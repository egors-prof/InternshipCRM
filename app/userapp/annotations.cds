using CRMService as service from '../../srv/service';
annotate service.Customers with @(
    UI.FieldGroup #GeneratedGroup : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'First Name',
                Value : firstName,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Last Name',
                Value : lastName,
            },
            {
                $Type : 'UI.DataField',
                Label : 'E-mail',
                Value : email,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Total Spend',
                Value : totalSpend,
            },
            
            { 
                $Type : 'UI.DataFieldForAnnotation', 
                Target:@UI.DataPoint#RatingDataPoint, 
                Label : 'Average Rating',
                @UI.Importance : #High,![@HTML5.CssDefaults] : { width : '10rem' }
            },
            {
                $Type : 'UI.DataField',
                Label : 'Status',
                Value : customerStatus_code,
            },
        ],
    },
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet1',
            Label : 'General Information',
            Target : '@UI.FieldGroup#GeneratedGroup',
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet2',
            Label : `Customer's Orders`,
            Target : 'orders/@UI.LineItem#Customer',
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet3',
            Label : `Customer's Interactions`,
            Target : 'interactions/@UI.LineItem#Interactions',
        },
    ],
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Label : 'Firstname',
            Value : firstName,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Lastname',
            Value : lastName,
        },
        {
            $Type : 'UI.DataField',
            Label : 'E-mail',
            Value : email,
        },
        {
            $Type : 'UI.DataField',
            Label : 'Status',
            Value : customerStatus_code,
        },
        
    ],
);
annotate service.Customers with {
    totalSpend @Measures.ISOCurrency : 'USD'
};
annotate service.Customers with @(
    UI.HeaderInfo : {
        TypeName       : 'Customer',
        TypeNamePlural : 'Customers',
        Title          : { $Type : 'UI.DataField', Value : lastName },
        Description    : { $Type : 'UI.DataField', Value : firstName }
    }
);

annotate service.Customers with @(
    UI.DataPoint #RatingDataPoint : {
        Value         : averageRating,
        Visualization : #Rating,
        TargetValue   : 5  ,
        MinimumValue : 0,
        NumberOfFractionalDigits : 0
    }
);



//ORDERS
annotate service.Orders with {
    totalAmount @Measures.ISOCurrency : 'USD';
};

annotate service.Orders with @(
    UI.QuickViewFacets : [
        {
            $Type : 'UI.ReferenceFacet',
            Target : '@UI.FieldGroup#OrderPopUp'
        }
    ],
    UI.FieldGroup #OrderPopUp : {
        Data : [
            { $Type : 'UI.DataField', Value : orderNumber, Label : 'Order Number' },
            { $Type : 'UI.DataField', Value : totalAmount, Label : 'Total Amount' },
            { $Type : 'UI.DataField', Value : status_code, Label : 'Status' }
        ]
    }
);
annotate service.Orders with @(
        UI.FieldGroup #GeneratedGroup : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'Order''s Number', 
                Value : orderNumber,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Total',
                Value : totalAmount,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Status',
                Value : status_code,
            },
        ],
    },
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet1',
            Label : 'General Information',
            Target : '@UI.FieldGroup#GeneratedGroup',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Order Items',
            ID : 'Facet_OrderItems',
            Target : 'items/@UI.LineItem',
        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Customer Interaction',
            ID : 'Facet_CustomerOrderFeedback',
            Target : 'reaction/@UI.FieldGroup#GeneralInfo',
        }
    ],
    UI.LineItem#Customer:[
        {
            $Type : 'UI.DataField',
            Label : 'Number',
            Value : orderNumber,
        },
        
        {
            $Type : 'UI.DataField',
            Label : 'Status',
            Value : status_code,
        }
    ]
);
annotate service.Orders with @(
    UI.HeaderInfo : {
        TypeName       : 'Order',
        TypeNamePlural : 'Orders', 
        Title          : { $Type : 'UI.DataField', Value : orderNumber },
        Description    : { $Type : 'UI.DataField', Value : customer.lastName }
    }

    
);



//ORDER ITEMS

annotate service.OrderItems with @(
    UI.HeaderInfo: {
        TypeName: 'Order Item',
        TypeNamePlural: 'Order Items',
        Title: {$Type : 'UI.DataField', Value: product.title }, 
        Description: { $Type : 'UI.DataField', Value: parent.orderNumber },
    }
);

annotate service.OrderItems with @(
    UI.FieldGroup #GeneratedGroup : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Label : 'Product',
                Value : product.title, 
            },
            
            {
                $Type : 'UI.DataField',
                Label : 'Quantity',
                Value : quantity, 
            },
            {
                $Type : 'UI.DataField',
                Label : 'Price at Order',
                Value : priceAtOrder, 
            }
        ]
    },
    
    UI.Facets : [
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet1',
            Label : 'General Information',
            Target : '@UI.FieldGroup#GeneratedGroup',
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet2',
            Label : 'Order Items From Same Order',
            Target : 'siblingItems/@UI.LineItem',
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet3',
            Label : 'Feedback on this Item',
            Target : 'reaction/@UI.FieldGroup#GeneralInfo',
        }
    ]
);
annotate service.OrderItems with {
    priceAtOrder @Measures.ISOCurrency : 'USD';
};
annotate service.OrderItems with @(
    UI.LineItem : [
        { $Type : 'UI.DataField', Value : product_content, Label : 'Preview', @UI.Importance : #High},
        { $Type : 'UI.DataField',Label : 'Product',Value : product.title,@UI.Importance : #High},
        { $Type : 'UI.DataField', Value : quantity ,Label:'Quantity',@UI.Importance : #High},
        { $Type : 'UI.DataField', Value : product_content,Label:'Product Content',@UI.Importance : #High },
        { $Type : 'UI.DataField', Value : priceAtOrder,Label:'Price At Order',@UI.Importance : #High }
    ]
);
annotate service.OrderItems with @(
    UI.DataPoint #RatingDataPoint : {
        Value         : rating,
        Visualization : #Rating,
        TargetValue   : 5  ,
        MinimumValue : 0,
        
    }
);
annotate service.OrderItems with {
    product_content @(
        Core.IsURl:false,
        IsImage:true
    );
};

annotate service.Interactions with {
    priority @(
        Common.ValueList : {
            $Type : 'Common.ValueListType',
            CollectionPath : 'Priorities',
            Parameters : [
                {
                    $Type : 'Common.ValueListParameterInOut',
                    LocalDataProperty : priority_code,
                    ValueListProperty : 'code'
                },
                {
                    $Type : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'name' 
                }
            ]
        },
        Common.Text : priority.name,
        Common.TextArrangement : #TextOnly
    );
};

annotate service.Interactions with @Common.SideEffects : {
    $Type : 'Common.SideEffectsType',
    TriggerAction : 'CRMService.createLog',
    TargetProperties : [
        'logs' 
    ]
};
annotate service.Interactions with @(
    UI.FieldGroup #Interactions : {
        $Type : 'UI.FieldGroupType',
        Data : [
            
            {
                $Type : 'UI.DataField',
                Label : 'Case Number', 
                Value : caseNumber
            },
            
            {
                $Type : 'UI.DataField',
                Label : 'Title',
                Value : title,
            },
            {
                $Type : 'UI.DataField',
                Value : order_ID,        
                Label : 'View Order Details'
            },
            {
                $Type : 'UI.DataField',
                Label : 'Status',
                Value : status_code,
            },
            
            {
                $Type : 'UI.DataField',
                Label : 'Summary',
                Value : summary,
            },
            
            {
                $Type : 'UI.DataField',
                Label : 'Resolution Note',
                Value : resolution
            },
            {
                $Type : 'UI.DataField',
                Label : 'Currently responsible',
                Value : currentOwner.name
            },
            { $Type: 'UI.DataFieldForAction', Action: 'CRMService.escalateToVendor', Label: 'Assign to Vendor' },
            { $Type: 'UI.DataFieldForAction', Action: 'CRMService.createLog', Label: 'Create Log' }



            
        ],
    },
    UI.Facets:[
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet1',
            Label : 'General Information',
            Target : '@UI.FieldGroup#Interactions',
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'OrderDetailsFacet',
            Label : 'Related Order Items',
            Target : 'order/items/@UI.LineItem', 
        },
        
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'LogsFacet',
            Label : 'Logs',
            Target : 'logs/@UI.LineItem'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID : 'GeneratedFacet3',
            Label : 'Feedback',
            Target : 'reaction/@UI.FieldGroup#GeneralInfo',
        },
        


    ],
    UI.LineItem#Interactions:[
            {
                $Type : 'UI.DataField',
                Label : 'Case Number', 
                Value : caseNumber
            },
            {
                $Type : 'UI.DataField',
                Label : 'Vendor',
                Value : vendor.name,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Priority',
                Value : priority_code,
            },
            {
                $Type : 'UI.DataField',
                Label : 'Status',
                Value : status_code,
            },
            

        

    ]
) ;

annotate service.InteractionLogs with {
    parent @UI.Hidden; 
};
annotate service.InteractionLogs with @(
    Capabilities.SelectRestrictions : {
        Selectable : true
    }
);
annotate service.InteractionLogs with {
    isPrivate @UI.Hidden: {$edmJson: {$Eq: [{$Type: 'String', $Value: 'Vendor'}, {$Type: 'String', $Value: '$user.role'}]}};
};
annotate service.InteractionLogs with @(
    UI.LineItem: [
        
        { $Type: 'UI.DataField', Value: createdBy, Label: 'Name',@UI.Importance: #High },
        { $Type: 'UI.DataField', Value: text, Label: 'Log Message',@UI.Importance: #High },
        { 
            $Type: 'UI.DataField', 
            Value: isPrivate, 
            Label: 'Private Note', 
            @UI.Importance: #High 
        },
        {  
            $Type: 'UI.DataFieldForAction',
            Action: 'CRMService.makeVisibleToVendor', 
            Label: 'Make Visible to Vendor',
            @UI.Hidden: {
                $edmJson: {
                    $Eq: [ 
                    { 
                        $Type: 'String', 
                        $Value: 'Vendor' 
                    }, 
                    {
                        $Type: 'String', 
                        $Value: '$user.role'
                    } 
                    ] 
                } 
            }

        }
        
            

    ]
);




annotate service.Interactions with @(
    UI.HeaderInfo : {
        TypeName       : 'Interaction',
        TypeNamePlural : 'Interactions', 
        Title          : { $Type : 'UI.DataField', Value : customer.firstName },
        Description    : { $Type : 'UI.DataField', Value :title  }
    }
);
annotate service.Interactions with {
    order @(
        Common.Text : order.orderNumber,
        Common.TextArrangement : #TextOnly
    );
};

annotate service.Feedbacks with @(
    UI.DataPoint #RatingDataPoint : {
        Value         : rating,
        Visualization : #Rating,
        TargetValue   : 5  ,
        MinimumValue : 0,
        NumberOfFractionalDigits : 0
    }
);

annotate service.Feedbacks with @(
    UI.FieldGroup #GeneralInfo : {
        $Type : 'UI.FieldGroupType',
        Data : [
            
            { 
                $Type : 'UI.DataFieldForAnnotation', 
                Target:@UI.DataPoint#RatingDataPoint, 
                Label : 'Rating',
                @UI.Importance : #High,![@HTML5.CssDefaults] : { width : '10rem' }
            },

            
            {
                $Type : 'UI.DataField',
                Label : 'Comment',
                Value : comment,
            }
            
        ],
    },
);
