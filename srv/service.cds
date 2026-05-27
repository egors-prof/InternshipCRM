using { CRM.models as my } from '../db/schema';

service CRMService @(requires: 'authenticated-user') {

    entity Customers as projection on my.Customer;
    
    // OPTIMIZED: Uses an explicit subquery check to avoid multi-array navigation issues
    annotate Customers with @restrict: [
        { grant: '*', to: 'CRMAdmin' },
        { 
            grant: 'READ', 
            to: 'Vendor', 
            where: 'exists orders.items[product.vendor.ID = $user.vendorId]' 
        }
    ];
    

    
    entity Orders as projection on my.Order {
        *,
        customer : redirected to Customers
    } actions {
        action refundOrder() returns Orders;
    }
    
    entity Interactions as projection on my.Interaction {
        *,
        customer : redirected to Customers,
        reaction : redirected to Feedbacks
    }actions {
        action escalateToVendor() returns Interactions;
    }

entity ProductReviews as select from my.Feedback {
    key ID,
    rating,
    comment,
    orderItem.product.ID as product_ID // Here, CAP allows path traversal in a SELECT!
};


    // OPTIMIZED: Cleans up deep array validation paths
    annotate Interactions with @restrict: [
        { grant: '*', to: 'CRMAdmin' },
        { 
            grant: 'READ', 
            to: 'Vendor', 
            where: 'exists customer.orders.items[product.vendor.ID = $user.vendorId] and currentOwner_code = ''VENDOR_ADMIN''' 
        }
    ];

    entity InteractionLogs as projection on my.InteractionLogs;
    entity Priorities as projection on my.Priorities;
    entity InteractionStatus as projection on my.InteractionStatus;

    annotate InteractionLogs with @restrict: [
        { grant: '*', to: 'CRMAdmin' }, 
        { 
            grant: ['READ', 'CREATE'], 
            to: 'Vendor', 
            where: 'isPrivate = false' 
        }
    ];

    @odata.draft.enabled
    entity Products as projection on my.Product{
        *,
        reviews : Association to many ProductReviews on reviews.product_ID = $self.ID
    }
    
    annotate Products with @restrict: [
        { grant: '*', to: 'CRMAdmin' }, 
        
        { grant: ['READ', 'UPDATE', 'DELETE'], to: 'Vendor', where: 'vendor_ID = $user.vendorId' },
        
        { grant: 'CREATE', to: 'Vendor' }
    ];
    @odata.draft.enabled
    entity MainCategories as projection on my.Category;
    entity SubCategories as projection on my.SubCategory;
    entity ProductGroups as projection on my.ProductGroup;

    @odata.draft.enabled
    @cds.redirection.target
    entity Feedbacks as projection on my.Feedback {
        *,
        customer : redirected to Customers
    };

    @readonly entity Statuses as projection on my.Statuses;
    @readonly entity CustomerStatuses as projection on my.CustomerStatuses;
    @readonly entity InteractionTypes as projection on my.InteractionTypes;
    entity OrderItems as projection on my.OrderItems;
    entity Roles as projection on my.Roles;
    entity Vendors as projection on my.Vendors actions {
        action banVendor();
        action unbanVendor();
    }
    annotate Vendors with @restrict: [
        { grant: '*', to: 'CRMAdmin' },
        
    ];

    type UserRoles : {
        isCRMAdmin : Boolean;
        isVendor   : Boolean;
        username   : String; 
    };
    
    function getMyRoles() returns UserRoles;
}