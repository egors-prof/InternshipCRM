using {CRM.models as my} from '../db/schema';
service PublicStorefrontService {
    @readonly
    entity Products as projection on my.Product {
        *,
        reviews : Association to many ProductReviews on reviews.product_ID = $self.ID,
        images  : Association to many ProductImage on images.product = $self,
    };
    entity ProductImage as projection on my.ProductImage {
        *,
        product : redirected to Products
    };

    entity ProductReviews as select from my.Feedback {
        key ID,
        rating,
        comment,
        orderItem.product.ID as product_ID
    };

    entity Wishlist as projection on my.Wishlists;

    @odata.draft.enabled
    entity MyProfile as projection on my.Customer;
    
    annotate MyProfile with @restrict: [
        { grant: ['READ', 'UPDATE'], to: 'Customer', where: 'ID = $user.customerId' }
    ];

    @odata.draft.enabled
    entity Orders as projection on my.Order {
        *,
        customer : redirected to MyProfile,
        items    : Composition of many OrderItems on items.parent = $self 
    };
    
    annotate Orders with @restrict: [
        { grant: ['READ', 'CREATE'], to: 'Customer', where: 'customer_ID = $user.customerId' }
    ];
    
    entity OrderItems as projection on my.OrderItems {
        *,
        parent : redirected to Orders,
        product.ID as product_vendor_ID
        
         
    };
    
    

    entity Interactions as projection on my.Interaction {
        *,
        customer : redirected to MyProfile,
        reaction : redirected to Feedbacks,

    };
    
    annotate Interactions with @restrict: [
        { grant: ['READ', 'CREATE'], to: 'Customer', where: 'customer_ID = $user.customerId' }
    ];

    entity Customers as projection on my.Customer;
    annotate Customers with @restrict: [
        { grant: ['READ'], to: 'Customer', where: 'ID = $user.customerId' } 
    ];

entity Vendors as projection on my.Vendors;
    annotate Vendors with @restrict: [
        { grant: '*READ', to: 'Customer' },
        
    ];
    


    @cds.redirection.target
    entity Feedbacks as projection on my.Feedback {
        *,
        customer    : redirected to MyProfile,
        order       : redirected to Orders,
        orderItem   : redirected to OrderItems,
        interaction : redirected to Interactions
    };
    
    annotate Feedbacks with @restrict: [
        { grant: ['READ', 'CREATE'], to: 'Customer', where: 'customer_ID = $user.customerId' }
    ];

    @readonly entity Statuses as projection on my.Statuses;
    @readonly entity InteractionTypes as projection on my.InteractionTypes;
    @readonly entity MainCategories as projection on my.Category;
    @readonly entity SubCategories as projection on my.SubCategory;
    @readonly entity ProductGroups as projection on my.ProductGroup;

        type UserRoles : {
        isCRMAdmin : Boolean;
        isVendor   : Boolean;
        username   : String; 
    };
    
    function getMyRoles() returns UserRoles;
}