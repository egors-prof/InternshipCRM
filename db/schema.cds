namespace CRM.models;
using { 
    managed, 
    cuid, 
    Currency ,
    sap.common.CodeList,
    sap,
} from '@sap/cds/common';
entity Customer : managed, cuid {
    firstName      : String(20);
    lastName       : String(20);
    email          : String @assert.format: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    
    totalSpend     : Decimal(15,2);
    virtual averageRating : Integer;
    customerStatus : Association to CustomerStatuses; 
    orders: Association to   many Order on orders.customer = $self;
    interactions   : Association to   many Interaction on interactions.customer = $self;
    
}
entity CustomerStatuses : CodeList {
    key code : String(10); 
}



entity Interaction : cuid, managed {
    caseNumber    : String(10);
    customer      : Association to Customer;
    vendor        : Association to Vendors;
    order         : Association to Order;
    
    type          : Association to InteractionTypes; 
    priority      : Association to Priorities;       
    status        : Association to InteractionStatus; 

    currentOwner  : Association to Roles; 
    
    title         : String(100);
    summary       : String(1000); 

    logs    : Composition of many InteractionLogs on logs.parent = $self;
    
    resolution    : String(1000);
    reaction      : Association to one Feedback on reaction.interaction = $self;
}


entity InteractionLogs : cuid, managed {
    parent    : Association to Interaction;
    text      : String(1000);
    author    : String;
    isPrivate : Boolean default true;
}


entity InteractionStatus : CodeList {
    key code : String(20);
    criticality : Integer; 
}


entity Priorities : CodeList {
    key code : String(20);
    criticality : Integer;
}


entity Roles : CodeList {
    key code : String(20);
}

entity InteractionTypes : CodeList {
    key code : String(20);
}



entity Order : managed, cuid {
    orderNumber  : String(10);
    totalAmount  : Decimal(10,2);
    status       : Association to Statuses;
    customer     : Association to Customer; 
    
    items        : Composition of many OrderItems on items.parent = $self;
    reaction     : Association to one Feedback on reaction.order = $self;
}


entity OrderItems : managed,cuid {
    
    parent : Association to one Order;
    product :Association to  one Product not null;
    quantity :Integer;
    priceAtOrder:Decimal(10,2) ;
    siblingItems : Association to many OrderItems on siblingItems.parent = $self.parent and siblingItems.ID != $self.ID;
    reaction : Association to one Feedback on reaction.orderItem = $self;

    

}
entity Statuses : sap.common.CodeList {
    key code : String(10);
    criticality : Integer; 
}
entity Feedback : cuid, managed {
    customer     : Association to Customer not null; 
    
   
    interaction  : Association to Interaction;
    order        : Association to Order;
    orderItem    : Association to OrderItems;
    
    
    feedbackType : String(20) enum {
        INTERACTION = 'INTERACTION'; 
        SHOP_ORDER  = 'SHOP_ORDER';  
        VENDOR_ITEM = 'VENDOR_ITEM'; 
    };

    
    @assert.format : '^[1-5]$' 
    rating       : Integer; 
    comment      : String(1000);
}

entity Product : managed, cuid {
    title        : String(20);
    desc         : String(100);
    category     : Association to ProductGroup;
    subCategory  : Association to SubCategory;
    mainCategory : Association to Category ;
    price        : Decimal(10,2);
    stock        : Integer;
    currency     : Currency;
    timesOrdered : Integer;
    vendor       : Association to Vendors;
    

    @Core.MediaType: mediaType
    content      : LargeBinary;
    @Core.IsMediaType: true
    mediaType    : String;

   
}




entity Category : managed, cuid {
    name          : String(50);
    description   : String(100);
    subCategories : Composition of many SubCategory on subCategories.parent = $self;
    products   : Association to many Product on products.mainCategory = $self;}


entity SubCategory : managed, cuid {
    name           : String(50);
    description    : String(100);
    parent         : Association to Category;
    productGroups  : Composition of many ProductGroup on productGroups.parent = $self;
    products       : Association to many Product on products.subCategory = $self;
}


entity ProductGroup : managed, cuid {
    name        : String(50);
    description : String(100);
    parent      : Association to SubCategory;
    products : Association to many Product on products.category = $self;
}

entity Vendors :cuid, managed {
  name      : String;
  contact   : String;
  email     : String;
  address   : String;
  isActive  : Boolean default true;
  products  : Association to many Product on products.vendor = $self;
  interactions : Association to many Interaction on interactions.vendor = $self;
}