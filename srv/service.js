const cds = require("@sap/cds");
const { SELECT, UPDATE } = cds.ql;
module.exports = class CRMService extends cds.ApplicationService {
  async init() {
    await super.init();
    const {
      Customers,
      Orders,
      OrderItems,
      Vendors,
      Products,
      InteractionLogs,
      Interactions,
      Feedbacks,
    } = this.entities;

    this.on("getMyRoles", async (req) => {
      console.log("🔒 Checking authorization attributes...");
      console.log("Is Admin:", req.user.is("admin"));
      console.log("Is CRMAdmin:", req.user.is("CRMAdmin"));

      let oCustomerDetails = null;
      const sCustomerId = req.user?.attr?.customerId || null;

      if (sCustomerId) {
        console.log(
          `👤 Extracting customer database row data for ID: [${sCustomerId}]`,
        );
        oCustomerDetails = await SELECT.one
          .from(Customers)
          .where({ ID: sCustomerId });
      }

      return {
        isCRMAdmin: req.user.is("CRMAdmin"),
        isVendor: req.user.is("Vendor"),
        username: req.user.id,
        id: req.user.id || sCustomerId,
        customerProfile: oCustomerDetails ? { ...oCustomerDetails } : null,
      };
    });

    this.before("NEW", "InteractionLogs", (req) => {
      req.data.author = req.user.id;

      if (req.user.is("Vendor")) {
        req.data.isPrivate = false;
      }
    });

    this.before(["UPDATE", "DELETE"], "InteractionLogs", (req) => {
      if (!req.data.IsActiveEntity === false) {
        req.reject(
          403,
          "Audit Compliance: Logs are immutable. You cannot edit or delete past comments.",
        );
      }
    });

    this.after("READ", "Customers", async (results, req) => {
      console.log(results);
      const customers = Array.isArray(results) ? results : [results];

      for (const customer of customers) {
        const feedbacks = await SELECT.from("Feedback").where({
          customer_ID: customer.ID,
        });
        console.log(customer.ID);
        const items = await SELECT.from(Orders, (o) => {
          o.items((item) => {
            (item.quantity, item.priceAtOrder);
          });
        }).where({ ID: customer.ID });
        console.log("items ", items);
        const orders = await SELECT.from("Order").where({
          customer_ID: customer.ID,
        });
        const orderIds = orders.map((order) => order.ID);
        console.log(orderIds);

        console.log("orders:", orders);

        let totalSpend = 0;
        if (orderIds.length > 0) {
          const items = await SELECT.from("OrderItems").where({
            parent_ID: { in: orderIds },
          });
          console.log("items:", items);
          for (const item of items) {
            totalSpend += item.quantity * item.priceAtOrder;
          }
        }
        let ratingSum = 0;
        for (const feedback of feedbacks) {
          ratingSum += feedback.rating;
        }

        console.log(
          "rating sum",
          ratingSum,
          "feedbacks length",
          feedbacks.length,
          "average",
          ratingSum / feedbacks.length,
        );
        console.log("total spend", totalSpend);
        customer.averageRating =
          feedbacks.length > 0 ? ratingSum / feedbacks.length : 0;
        customer.totalSpend = totalSpend;
      }
    });

    this.before("SAVE", "Orders", async (req) => {
      const oOrderData = req.data;
      console.log(`🔒 Validating Order Activation for ID: ${oOrderData.ID}`);
      if (!oOrderData.items || oOrderData.items.length === 0) {
        return req.error(
          400,
          "Cannot activate an order with an empty shopping cart.",
        );
      }
      let nFinalValidatedTotal = 0;
      for (const item of oOrderData.items) {
        const dbProduct = await SELECT.one
          .from("CRMService.Products")
          .where({ ID: item.product_ID });
        if (!dbProduct) {
          return req.error(
            404,
            `Product validation error: Item ID ${item.product_ID} no longer exists.`,
          );
        }

        if (item.quantity > dbProduct.stock) {
          return req.error(
            400,
            `Insufficient stock for '${dbProduct.title}'. Available in warehouse: ${dbProduct.stock}, requested: ${item.quantity}`,
          );
        }
        item.priceAtOrder = dbProduct.price;

        nFinalValidatedTotal += dbProduct.price * item.quantity;

        const nNewStockLevel = dbProduct.stock - item.quantity;
        const nNewTimesOrdered = dbProduct.timesOrdered + item.quantity;
        await UPDATE("CRMService.Products")
          .set({ stock: nNewStockLevel, timesOrdered: nNewTimesOrdered })
          .where({ ID: item.product_ID });

        console.log(
          `📦 Inventory Updated: '${dbProduct.title}' stock reduced to ${nNewStockLevel}`,
        );
      }

      oOrderData.totalAmount = nFinalValidatedTotal;

      console.log(
        `✅ Order validation successful. Moving transactions safely to main tables!`,
      );
    });

    this.before("CREATE", Feedbacks, async (req) => {
      console.log("--> Backend feedback creation handler triggered!");
      if (req.target && req.target.name !== "CRMService.Feedbacks") {
        console.log(
          `⏭️ Side-effect routing detected from [${req.target.name}]. Skipping review checks.`,
        );
        return;
      }

      const data = req.data;
      let targetCount = 0;
      console.log(data);
      if (data.interaction_ID) {
        data.feedbackType = "INTERACTION";
        targetCount++;
      }
      if (data.order_ID) {
        data.feedbackType = "SHOP_ORDER";
        targetCount++;
      }
      if (data.orderItem_ID) {
        data.feedbackType = "VENDOR_ITEM";
        targetCount++;
      }

      if (targetCount === 0) {
        return req.error(
          400,
          "Invalid payload context. Feedback must link exclusively to an Interaction, Shop Order, or Vendor Item.",
        );
      }

      if (targetCount > 1) {
        return req.error(
          400,
          "Ambiguous payload context. Feedback cannot link to multiple target entities simultaneously.",
        );
      }
    });

    this.before("SAVE", "Products", async (req) => {
      console.log("draft activcation ");
      if (req.user.is("Vendor")) {
        const draftData = req.data;

        draftData.vendor_ID = req.user.attr.vendorId;

        console.log(
          `🔒 Draft Activation: Bound Vendor ID ${draftData.vendor_ID} permanently to active product.`,
        );
      }
    });

    this.after("READ", "Orders", async (results, req) => {
      const orders = Array.isArray(results) ? results : [results];
      console.log(orders);
      console.log("user", req.user);
      let items = [];

      for (const order of orders) {
        if (req.user.is("CRMAdmin")) {
          console.log("CRMAdmin");
          items = await SELECT.from("CRMService.OrderItems").where({
            parent_ID: order.ID,
          });
        } else if (req.user.is("Customer")) {
          console.log("Customer");
          items = await SELECT.from("CRMService.OrderItems").where({
            parent_ID: order.ID,
            "parent.customer_ID": req.user.attr.customerId,
          });
        } else {
          console.log("else");
          items = await SELECT.from("CRMService.OrderItems").where({
            parent_ID: order.ID,
            "product.vendor_ID": req.user.attr.vendorId,
          });
        }

        console.log("items", items);

        let calculatedTotal = 0;
        calculatedTotal = items.reduce(
          (calculatedTotal, item) =>
            calculatedTotal + item.quantity * item.priceAtOrder,
          0,
        );
        console.log("calc", calculatedTotal);

        order.totalAmount = calculatedTotal;
      }
      console.log(orders);
    });

    this.after("READ", "Vendors", async (results, req) => {
      console.log(results);
      if (!results) return;

      const vendors = Array.isArray(results) ? results : [results];

      for (const vendor of vendors) {
        if (!vendor.ID) continue;

        const products = await SELECT.from("CRMService.Products").where({
          vendor_ID: vendor.ID,
        });

        let productIDs = products.map((p) => p.ID);
        let total = 0;

        if (productIDs.length > 0) {
          const items = await SELECT.from("CRMService.OrderItems").where({
            product_ID: { in: productIDs },
          });

          for (const item of items) {
            total += item.priceAtOrder * item.quantity;
          }
        }

        vendor.totalAmount = total;
      }
    });

    this.on("banVendor", Vendors, async (req) => {
      if (!req.user.is("CRMAdmin")) {
        return req.reject(403, "Only CRM Admins can ban vendors.");
      }
      const vendorID = req.params[0].ID;
      const vendor = await SELECT.one
        .from(Vendors)
        .where({ ID: vendorID })
        .columns("isActive");
      if (vendor.isActive === false) {
        return req.reject(400, "This vendor is already banned!");
      }
      await UPDATE(Vendors).set({ isActive: false }).where({ ID: vendorID });
      req.notify("Vendor has been successfully banned.");
    });

    this.on("unbanVendor", Vendors, async (req) => {
      if (!req.user.is("CRMAdmin")) return req.reject(403);
      const vendorID = req.params[0].ID;
      const vendor = await SELECT.one
        .from(Vendors)
        .where({ ID: vendorID })
        .columns("isActive");
      if (vendor.isActive === true) {
        return req.reject(400, "This vendor is already active and not banned.");
      }
      await UPDATE(Vendors).set({ isActive: true }).where({ ID: vendorID });
      req.notify("Vendor access restored.");
    });

    this.on("escalateToVendor", Interactions, async (req) => {
      console.log("escalate ");

      if (!req.user.is("CRMAdmin")) {
        return req.reject(
          403,
          "Only CRM Admins can assign interactions to vendors.",
        );
      }
      console.log("params:", req.params);
      const interactionID = req.params[1].ID;
      console.log(interactionID);
      await UPDATE(Interactions)
        .set({ isPrivate: false })
        .where({ ID: interactionID });
      await UPDATE(Interactions)
        .set({ currentOwner_code: "VENDOR_ADMIN" })
        .where({ ID: interactionID });
      req.notify("Interaction has been escalated to vendor.");
    });

    this.on("makeVisibleToVendor", InteractionLogs, async (req) => {
      console.log("make visible to vendor");
      if (!req.user.is("CRMAdmin")) {
        return req.reject(
          403,
          "Only CRM Admins can make interaction logs visible to vendors.",
        );
      }
      console.log("params:", req.params);
      await UPDATE(InteractionLogs)
        .set({ isPrivate: false })
        .where({ ID: req.params[2].ID });
      req.notify("Interaction log is now visible to vendor.");
    });

    this.on("createLog", Interactions, async (req) => {
      console.log("👤 User executing createLog:", req.user.id);
      const { text } = req.data;

      const interactionID = req.params[1]?.ID;
      console.log(req.params[0]?.ID);
      console.log(req.params[1]?.ID);
      console.log(req.params[2]?.ID);

      console.log(
        `Creating log for interaction [${interactionID}] with text: "${text}"`,
      );

      let bIsPrivate = true;
      if (req.user.is("Vendor")) {
        console.log("Vendor creating log, setting isPrivate to false");
        bIsPrivate = false;
      } else {
        console.log("CRMAdmin creating log, setting isPrivate to true");
        bIsPrivate = true;
      }

      const oCreatedLog = await cds.tx(req).run(
        INSERT.into(InteractionLogs).entries({
          text: text,
          parent_ID: interactionID,
          isPrivate: bIsPrivate,
          author: req.user.id,
        }),
      );

      req.notify("Log created successfully.");

      return await cds.tx(req).run(
         SELECT.one.from(InteractionLogs).where({ parent_ID: interactionID, text: text })
      );
    });

    this.before("NEW", "InteractionLogs", async (req) => {
      if (req.user.is("Vendor")) {
        req.data.isPrivate = false;
      }
    });

    this.before("CREATE", "InteractionLogs", async (req) => {
      if (req.user.is("Vendor")) {
        req.data.isPrivate = false;
      }
    });
  }
};
