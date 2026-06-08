const cds = require('@sap/cds');
const { SELECT, UPDATE } = cds.ql;
module.exports = class CRMService extends cds.ApplicationService {
    async init() {
       
        await super.init();
        const { Customers, Orders, OrderItems,Vendors,Products,InteractionLogs,Interactions,Feedbacks} = this.entities;

    
        
        this.on('getMyRoles', async (req) => {
            console.log("🔒 Checking authorization attributes...");
            console.log('Is Admin:', req.user.is('admin'));
            console.log('Is CRMAdmin:', req.user.is('CRMAdmin'));

            let oCustomerDetails = null;
            const sCustomerId = req.user?.attr?.customerId || null;
            

            if (sCustomerId) {
                console.log(`👤 Extracting customer database row data for ID: [${sCustomerId}]`);
                oCustomerDetails = await SELECT.one.from(Customers).where({ ID: sCustomerId });
            }

            return {
                isCRMAdmin: req.user.is('CRMAdmin'),
                isVendor: req.user.is('Vendor'),
                username: req.user.id,
                id: sCustomerId,
                
                
                customerProfile: oCustomerDetails 
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

        this.after('READ','Customers', async (results,req) => {
            console.log(results);
            const customers = Array.isArray(results) ? results : [results];
        
            for (const customer of customers) {
                const feedbacks = await SELECT.from('Feedback').where({ customer_ID: customer.ID });
                const orders = await SELECT.from('Order').where({ customer_ID: customer.ID,});
                const orderIds = orders.map(order => order.ID);

                console.log('orders:',orders)
                
                let totalSpend = 0;
                if (orderIds.length > 0) {
                    const items = await SELECT.from('OrderItems').where({ parent_ID: { 'in': orderIds } });
                    console.log('items:',items)
                    for (const item of items) {
                        totalSpend += (item.quantity * item.priceAtOrder);
                    }
                }
                let ratingSum =0 ;
                for (const feedback of feedbacks) {
                    ratingSum+=feedback.rating;
                }
                
                console.log('rating sum',ratingSum, 'feedbacks length', feedbacks.length, 'average', ratingSum/feedbacks.length);
                console.log('total spend', totalSpend);
                customer.averageRating =feedbacks.length > 0 ? ratingSum/feedbacks.length : 0;
                customer.totalSpend = totalSpend;
                
        }
        });
      
this.before('SAVE', 'Orders', async (req) => {
    const oOrderData = req.data;
    console.log(`🔒 Validating Order Activation for ID: ${oOrderData.ID}`);

    // 1. Safety Guard: Verify the order contains line items
    if (!oOrderData.items || oOrderData.items.length === 0) {
        return req.error(400, "Cannot activate an order with an empty shopping cart.");
    }

    let nFinalValidatedTotal = 0;

    // 2. Loop through the items to protect warehouse stock and confirm prices
    for (const item of oOrderData.items) {
        // Read the true, immutable product details directly from the main master table
        const dbProduct = await SELECT.one.from('CRMService.Products').where({ ID: item.product_ID });
        
        if (!dbProduct) {
            return req.error(404, `Product validation error: Item ID ${item.product_ID} no longer exists.`);
        }

        // ⚠️ WAREHOUSE STOCK GUARDRAIL
        if (item.quantity > dbProduct.stock) {
            return req.error(400, `Insufficient stock for '${dbProduct.title}'. Available in warehouse: ${dbProduct.stock}, requested: ${item.quantity}`);
        }

        // ⚠️ FINANCIAL FRAUD GUARDRAIL
        // Snap the official database catalog price onto the ledger line item.
        // This completely prevents users from manipulating prices via browser tools!
        item.priceAtOrder = dbProduct.price;
        
        nFinalValidatedTotal += (dbProduct.price * item.quantity);

        // 3. Deduct the purchased quantity from the master inventory stock level safely
        const nNewStockLevel = dbProduct.stock - item.quantity;
        const nNewTimesOrdered=dbProduct.timesOrdered+item.quantity;
        await UPDATE('CRMService.Products')
            .set({ stock: nNewStockLevel,timesOrdered:nNewTimesOrdered })
            .where({ ID: item.product_ID });
            
        console.log(`📦 Inventory Updated: '${dbProduct.title}' stock reduced to ${nNewStockLevel}`);
    }

    // Lock in the mathematically sound total directly onto the parent Order document header
    oOrderData.totalAmount = nFinalValidatedTotal;
    
    console.log(`✅ Order validation successful. Moving transactions safely to main tables!`);
});

// ================================================================= */
        // OPTIMIZED: Context-Aware Feedback Creation Validation Engine       */
        // ================================================================= */
        this.before('CREATE', Feedbacks, async (req) => {
            console.log('--> Backend feedback creation handler triggered!');
            if (req.target && req.target.name !== 'CRMService.Feedbacks') {
                console.log(`⏭️ Side-effect routing detected from [${req.target.name}]. Skipping review checks.`);
                return;
            }

            const data = req.data;
            let targetCount = 0;
            console.log(data);

            // 1. Evaluate context bindings and map classification type flags cleanly
            if (data.interaction_ID) {
                data.feedbackType = 'INTERACTION';
                targetCount++;
            }
            if (data.order_ID) {
                data.feedbackType = 'SHOP_ORDER';
                targetCount++;
            }
            if (data.orderItem_ID) {
                data.feedbackType = 'VENDOR_ITEM';
                targetCount++;
            }

            // 2. Multi-Context Mutual Exclusivity Guardrails
            if (targetCount === 0) {
                return req.error(400, "Invalid payload context. Feedback must link exclusively to an Interaction, Shop Order, or Vendor Item.");
            }
            
            if (targetCount > 1) {
                return req.error(400, "Ambiguous payload context. Feedback cannot link to multiple target entities simultaneously.");
            }

           
            
        });

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
    this.after('READ', 'Orders', async (results,req) => {
        
    const orders = Array.isArray(results) ? results : [results];
    console.log(orders)
    console.log('user',req.user);
    let items = [] ;
    

    // Loop through every order Fiori asked for
    for (const order of orders) {
        if(req.user.is('CRMAdmin')){
            console.log('CRMAdmin');
            items = await SELECT.from('CRMService.OrderItems').where({ 
                                        parent_ID: order.ID
                                        }); 
                
        }else if (req.user.is('Customer')){
            console.log("Customer");
            items = await SELECT.from('CRMService.OrderItems').where({ 
                                        parent_ID: order.ID, 
                                        'parent.customer_ID': req.user.attr.customerId });
        }else{
            console.log('else');
            items = await SELECT.from('CRMService.OrderItems').where({ 
                                        parent_ID: order.ID, 
                                        'product.vendor_ID': req.user.attr.vendorId });
        }
       
        console.log('items',items);
        
        // 2. Calculate the math (Quantity * Price)
        let calculatedTotal = 0;
        for (const item of items) {
            calculatedTotal += (item.quantity * item.priceAtOrder);
        }

        // 3. Attach it to your virtual field!
        order.totalAmount = calculatedTotal;
    }
    console.log(orders);
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