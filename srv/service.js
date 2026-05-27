const cds = require('@sap/cds');
const { SELECT, UPDATE } = cds.ql;
module.exports = class CRMService extends cds.ApplicationService {
    async init() {
       
        await super.init();
        const { Customers, Orders, OrderItems,Vendors,Products,Interactions } = this.entities;

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


        this.on('READ', Customers, async (req, next) => {
            console.log('customer req', req);
            
            if (req?.params[0]?.ID) {
                let ids = [];
                let total = 0;
                let ratingSum = 0;
                const customerID = req?.params[0]?.ID;
                
                console.log(customerID);
                console.log('obj page');
                
                // Get the standard customer data from the database
                const customer = await next();
                customer.averageRating = 5.0;
                
                const orders = await SELECT.from(Orders).where({ customer_ID: customerID });
                for (const order of orders) {
                    ids.push(order.ID);
                }
                
                console.log('ids', ids);
                
                if (ids.length > 0) {
                    const items = await SELECT.from(OrderItems).where({ parent_ID: { in: ids } });
                    console.log(items);
                    
                    for (const item of items) {
                        total += item.priceAtOrder * item.quantity;
                        ratingSum += item.rating;
                    }
                    
                    customer.totalSpend = total;
                    customer.averageRating = ratingSum / items.length;
                }
            } else {
                return next();
            }
        });

        this.before('SAVE', 'Products', async (req) => {
        if (req.data.content) {
            const targetStream = req.data.content;
        }
    });
// this.before('NEW', 'Products', (req) => {
//         // Initialize the composition child for the file binary
//         req.data.image = { 
//             ID: cds.utils.uuid(),
//             mediaType: 'image/png' 
//         };

//         // Fiori relies on this root-level property being populated to avoid the UI crash
//         req.data.mediaType = 'image/png'; 

//         // Apply vendor security context
//         if (req.user.is('Vendor')) {
//             req.data.vendor_ID = req.user.attr.vendorId;
//         }
//     });
// this.on('READ', 'Products', async (req, next) => {
//     const result = await next();
//     // FIXED: Use req.params[0] to catch GET request URL parameters!
//     if (result == null && req.params && req.params[0]?.IsActiveEntity === false) {
//         return { 
//             ID: req.params[0].ID, 
//             IsActiveEntity: false, 
//             HasActiveEntity: true 
//         };
//     }
//     return result;
// });

        this.on('READ', Orders, async (req, next) => {
            console.log('log: order');
            const url = req._.req.url;
            let containsInteractions = url.toLowerCase().includes('interactions');
            
            console.log(url);
            console.log('contains: ', containsInteractions);
            console.log('url\tfullurl');
            console.log(req.target.name);
            
            if (req?.params.length == 2) {
                const order = await next();
                const orderID = order.ID;
                
                console.log('order', order, 'orderID', orderID);
                
                const items = await SELECT.from(OrderItems).where({ parent_ID: orderID });
                console.log(items);
                
                let total = 0;
                for (const item of items) {
                    total += item.priceAtOrder * item.quantity;
                }
                
                console.log('total', total);
                order.totalAmount = total;
            } else {
                return next();
            }
        });

// this.on('READ', Vendors, async (req, next) => {

//         if (!req.params || req.params.length === 0 || !req.params[0].ID) {
//             return await next(); 
//         }

//         const vendorID = req.params[0].ID;
        
//         const vendor = await next(); 
//         if (!vendor) return vendor; 

//         const products = await SELECT.from(Products).where({ vendor_ID: vendorID });
        
//         let productIDs = [];
//         for (const prod of products) {
//             productIDs.push(prod.ID);
//         }

//         let total = 0;
//         if (productIDs.length > 0) {
//             const items = await SELECT.from(OrderItems).where({ product_ID: { 'in': productIDs } });
            
//             for (const item of items) {
//                 total += (item.priceAtOrder * item.quantity);
//             }
//         }

//         vendor.totalAmount = total;

//         return vendor;
//     });

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
    }
}