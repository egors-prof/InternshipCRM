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
            console.log("user: ",req.user);
            

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


 this.after('READ', 'Orders', async (results, req) => {
    // 🟢 SAFETY CHECK 1: If there are no results, exit immediately to protect the draft state
    if (!results) return;

    const orders = Array.isArray(results) ? results : [results];
    console.log("Orders received in hook:", orders);
    console.log('User profile:', req.user);
    
    let items = [];

    // Loop through every order requested
    for (const order of orders) {
        // 🟢 SAFETY CHECK 2: Skip empty, malformed, or half-baked draft objects safely
        if (!order || !order.ID) continue;

        if (req.user.is('CRMAdmin')) {
            console.log('CRMAdmin');
            items = await SELECT.from('CRMService.OrderItems').where({ 
                parent_ID: order.ID
            }); 
                
        } else if (req.user.is('Customer')) {
            console.log("Customer");
            items = await SELECT.from('CRMService.OrderItems').where({ 
                parent_ID: order.ID, 
                'parent.customer_ID': req.user.attr.customerId 
            });
        } else {
            console.log('Else/Vendor');
            items = await SELECT.from('CRMService.OrderItems').where({ 
                parent_ID: order.ID, 
                'product.vendor_ID': req.user.attr.vendorId 
            });
        }
       
        console.log('Associated Line Items:', items);
        
        // 2. Calculate totals (Quantity * Price)
        let calculatedTotal = 0;
        for (const item of items) {
            if (item && item.quantity && item.priceAtOrder) {
                calculatedTotal += (item.quantity * item.priceAtOrder);
            }
        }

        // 3. Attach it to your virtual UI field safely
        order.totalAmount = calculatedTotal;
    }
    console.log("Orders processing cycle complete:", orders);
});




        this.before('CREATE', 'Feedbacks', async (req) => {
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



    }
};