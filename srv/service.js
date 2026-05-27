const cds = require('@sap/cds');
const { SELECT, UPDATE } = cds.ql;
module.exports = class CRMService extends cds.ApplicationService {
    async init() {
       
        await super.init();
        const { Customers, Orders, OrderItems,Vendors,Products,InteractionLogs,Interactions,Feedback} = this.entities;

        this.on('getMyRoles', (req) => {
            console.log(req.user.is('admin'));
            console.log(req.user.is('CRMAdmin'));

            return {
                isCRMAdmin: req.user.is('CRMAdmin'),
                isVendor: req.user.is('Vendor'),
                username: req.user.id
            };
        });


        this.before('NEW', 'InteractionLogs', (req) => {
            req.data.author = req.user.id;

            if (req.user.is('Vendor')) {
                req.data.isPrivate = false;
            }
        });

        this.before(['UPDATE', 'DELETE'], 'InteractionLogs', (req) => {
            if (!req.data.IsActiveEntity === false) { 
                req.reject(403, 'Audit Compliance: Logs are immutable. You cannot edit or delete past comments.');
            }
        });

        this.after('READ','Customers', async (results) => {
            console.log(results);
            const customers = Array.isArray(results) ? results : [results];
        
            for (const customer of customers) {
                const feedbacks = await SELECT.from('Feedback').where({ customer_ID: customer.ID });
                const orders = await SELECT.from('Order').where({ customer_ID: customer.ID });
                const orderIds = orders.map(order => order.ID);
                console.log('orders:',orders)
                
                let totalSpend = 0;
                if (orderIds.length > 0) {
                    const items = await SELECT.from('OrderItems').where({ parent_ID: { 'in': orderIds } });
                    for (const item of items) {
                        totalSpend += (item.quantity * item.priceAtOrder);
                    }
                }
                let ratingSum =0 ;
                for (const feedback of feedbacks) {
                    ratingSum+=feedback.rating;
                }
                
                console.log('rating sum',ratingSum, 'feedbacks length', feedbacks.length, 'average', ratingSum/feedbacks.length);
                customer.averageRating =feedbacks.length > 0 ? ratingSum/feedbacks.length : 0;
                customer.totalSpend = totalSpend;
                
        }
        });
        // this.on('READ', Customers, async (req, next) => {
        //     console.log('customer req', req);
            
        //     if (req?.params[0]?.ID) {
        //         let ids = [];
        //         let total = 0;
        //         let ratingSum = 0;
        //         const customerID = req?.params[0]?.ID;
                
        //         console.log(customerID);
        //         console.log('obj page');
                
        //         // Get the standard customer data from the database
        //         const customer = await next();
        //         customer.averageRating = 5.0;
                
        //         const orders = await SELECT.from(Orders).where({ customer_ID: customerID });
        //         for (const order of orders) {
        //             ids.push(order.ID);
        //         }
                
        //         console.log('ids', ids);
                
        //         if (ids.length > 0) {
        //             const items = await SELECT.from(OrderItems).where({ parent_ID: { in: ids } });
        //             console.log(items);
                    
        //             for (const item of items) {
        //                 total += item.priceAtOrder * item.quantity;
        //                 ratingSum += item.rating;
        //             }
                    
        //             customer.totalSpend = total;
        //             customer.averageRating = ratingSum / items.length;
        //         }
        //     } else {
        //         return next();
        //     }
        // });


this.before('SAVE', 'Products', async (req) => {
    // 1. Double check the user is logged in as a Vendor
    console.log('draft activcation ')
    if (req.user.is('Vendor')) {
        
        // 2. Read the draft data currently being activated
        const draftData = req.data;
        
        // 3. Inject their vendorId session attribute into the activation payload
        draftData.vendor_ID = req.user.attr.vendorId;
        
        console.log(`🔒 Draft Activation: Bound Vendor ID ${draftData.vendor_ID} permanently to active product.`);
    }
});
    this.after('READ', 'Orders', async (results) => {

    const orders = Array.isArray(results) ? results : [results];

    // Loop through every order Fiori asked for
    for (const order of orders) {
        
        // 1. Fetch the items belonging to this specific order from the database
        // (Make sure to use your actual database table name and foreign key here)
        const items = await SELECT.from('CRMService.OrderItems').where({ parent_ID: order.ID });

        // 2. Calculate the math (Quantity * Price)
        let calculatedTotal = 0;
        for (const item of items) {
            calculatedTotal += (item.quantity * item.priceAtOrder);
        }

        // 3. Attach it to your virtual field!
        order.totalAmount = calculatedTotal;
    }
});


// FIXED: Using 'after' lets CAP fetch the database rows automatically first!
    this.after('READ', 'Vendors', async (results, req) => {
        
        // 1. Safety check: Ensure we have data to work with
        console.log(results);
        if (!results) return;

        // 2. Normalize the data into an array (handles both the List View and Single Vendor View)
        const vendors = Array.isArray(results) ? results : [results];

        // 3. Loop through the fetched vendors to calculate their dynamic totals
        for (const vendor of vendors) {
            
            // Skip if there's no ID (e.g., a count request)
            if (!vendor.ID) continue;

            // Fetch products belonging to this vendor
            const products = await SELECT.from('CRMService.Products').where({ vendor_ID: vendor.ID });
            
            // Extract just the product IDs into an array
            let productIDs = products.map(p => p.ID);
            let total = 0;

            // If the vendor has products, fetch all related order items to calculate revenue
            if (productIDs.length > 0) {
                const items = await SELECT.from('CRMService.OrderItems').where({ product_ID: { 'in': productIDs } });
                
                for (const item of items) {
                    total += (item.priceAtOrder * item.quantity);
                }
            }

            // 4. Attach the calculated total back to the vendor record
            // (Ensure you have 'virtual totalAmount : Decimal;' in your Vendors schema!)
            vendor.totalAmount = total;
        }
    });

        this.on('banVendor', Vendors, async (req) => {
            if (!req.user.is('CRMAdmin')) {
                return req.reject(403, "Only CRM Admins can ban vendors.");
            }
            const vendorID = req.params[0].ID;
            const vendor = await SELECT.one.from(Vendors).where({ ID: vendorID }).columns('isActive');
            if (vendor.isActive === false) {
                return req.reject(400, "This vendor is already banned!"); 
            }
            await UPDATE(Vendors).set({ isActive: false }).where({ ID: vendorID });
            req.notify("Vendor has been successfully banned.");
        });

        this.on('unbanVendor', Vendors, async (req) => {
            if (!req.user.is('CRMAdmin')) return req.reject(403);
            const vendorID = req.params[0].ID;
            const vendor = await SELECT.one.from(Vendors).where({ ID: vendorID }).columns('isActive');
            if (vendor.isActive === true) {
                return req.reject(400, "This vendor is already active and not banned.");
            }
            await UPDATE(Vendors).set({ isActive: true }).where({ ID: vendorID });
            req.notify("Vendor access restored.");
        });
        
        this.on('escalateToVendor', Interactions, async (req) => {
            console.log('escalate ')
            
            if (!req.user.is('CRMAdmin')) {
                return req.reject(403, "Only CRM Admins can assign interactions to vendors.");
            }
            console.log('params:' ,req.params)
            const interactionID = req.params[1].ID;
            console.log(interactionID);
            await UPDATE(Interactions).set({ isPrivate: false }).where({ ID: interactionID });
            await UPDATE(Interactions).set({currentOwner_code: 'VENDOR_ADMIN'}).where({ ID: interactionID });
            req.notify("Interaction has been escalated to vendor.");
        });

        this.on('makeVisibleToVendor', InteractionLogs, async (req) => {
            console.log('make visible to vendor')
            if (!req.user.is('CRMAdmin')) {
                return req.reject(403, "Only CRM Admins can make interaction logs visible to vendors.");
            }
            console.log('params:' ,req.params)
            await UPDATE(InteractionLogs).set({ isPrivate: false }).where({ ID: req.params[2].ID });
            req.notify("Interaction log is now visible to vendor.");
        })
        this.on('createLog',Interactions,async (req) => {
            console.log(req.user)
            const { text } = req.data;
            const interactionID = req.params[1].ID;
            console.log('Creating log for interaction', interactionID, 'with text:', text);
            if (req.user.is('Vendor')) {
                console.log('Vendor creating log, setting isPrivate to false');
                await INSERT.into(InteractionLogs).entries({
                text: text,
                parent_ID: interactionID,
                isPrivate: false
            });
            }else{
                console.log('CRMAdmin creating log, setting isPrivate to true');
                await INSERT.into(InteractionLogs).entries({
                    text: text,
                    parent_ID: interactionID,
                    isPrivate: true
                    
                });
            }
            
            req.notify("Log created successfully.");
        });
        this.before('NEW', 'InteractionLogs', async (req) => {
            if (req.user.is('Vendor')) {
                req.data.isPrivate = false;
            }
        });

        this.before('CREATE', 'InteractionLogs', async (req) => {
            if (req.user.is('Vendor')) {
                req.data.isPrivate = false;
            }
        });
        
    }
    
}