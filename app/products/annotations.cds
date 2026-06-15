using CRMService as crm from '../../srv/service';

annotate crm.Products with @(
    UI.HeaderInfo : {
        TypeName       : 'Product',
        TypeNamePlural : 'Products',
        Title          : {
            $Type : 'UI.DataField',
            Value : title,
        },
        Description    : {
            $Type : 'UI.DataField',
            Value : desc,        
        },
        ImageUrl       : content
    }
);

annotate crm.ProductImage with {
    
    content   
        @Core.MediaType : mediaType
        @Core.ContentDisposition.Type: 'inline'
        @UI.IsImage : true;
              
    mediaType @Core.IsMediaType: true;
};

annotate crm.Products with {
    content   @Core.MediaType : mediaType
              @Core.ContentDisposition.Type: 'inline'
              @UI.IsImage : true;  
              
    mediaType @Core.IsMediaType: true;


    price     @Measures.ISOCurrency : 'USD';

    stock     @HTML5.ControlHint : #StepInput
              @HTML5.StepInput.Step : 1
              @Common.Validation.Minimum : 0;
};


annotate crm.ProductReviews with @(
    UI.LineItem : [
        { 
            $Type : 'UI.DataFieldForAnnotation', 
            Target:@UI.DataPoint#RatingFeedback, 
            Label : 'Average Rating',
            @UI.Importance : #High,
            ![@HTML5.CssDefaults] : { width : '10rem' }
        },
        {
            $Type : 'UI.DataField',
            Label : 'Comment',
            Value : comment,
            @UI.Importance : #Medium,
            ![@HTML5.CssDefaults] : { width : '20rem' }
        }
    ]
);
annotate crm.ProductReviews with @(
    UI.DataPoint #RatingFeedback : {
        Value         : rating,
        Visualization : #Rating,
        TargetValue   : 5  ,
        MinimumValue : 0,
        NumberOfFractionalDigits : 0
    }
);
annotate crm.Products with @(
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Value : title,
            Label : 'Product Name'
        },
        {
            $Type : 'UI.DataField',
            Value : price,
            Label : 'Unit Price'
        },
        {
            $Type : 'UI.DataField',
            Value : content,       
            Label : 'Image Preview',
            @UI.IsImageURL : true   
        },
        {
            $Type : 'UI.DataField',
            Value : stock,
            Label : 'Inventory Count'
        }
    ]
);


annotate crm.Products with @(
    UI.FieldGroup #GeneralProductDetails : {
        $Type : 'UI.FieldGroupType',
        Data : [
            { $Type : 'UI.DataField', Value : title, Label : 'Product Name' },
            { $Type : 'UI.DataField', Value : price, Label : 'Unit Price' },
            { $Type : 'UI.DataField', Value : stock, Label : 'Inventory Count' },
            {
            $Type : 'UI.DataField',
            Value : content,       
            Label : 'Image Preview',
            @UI.IsImageURL : true,
            @Core.MediaType : mediaType,
            @Core.ContentDisposition.Type: 'inline',
        },
        ]
    }
);
annotate crm.Products with @(
    UI.FieldGroup #ProductClassifications : {
        $Type : 'UI.FieldGroupType',
        Data : [
            
            { 
                $Type : 'UI.DataField', 
                Value : mainCategory_ID, 
                Label : 'Department' 
            },
            { 
                $Type : 'UI.DataField', 
                Value : subCategory_ID,  
                Label : 'Category' 
            },
            { 
                $Type : 'UI.DataField', 
                Value : category_ID,     
                Label : 'Segment' 
            }
        ]
    }
);
annotate crm.MainCategories with {
    name        @Common.Label : 'Name';
    description @Common.Label : 'Description';
};
annotate crm.SubCategories with {
    name        @Common.Label : 'Name';
    description @Common.Label : 'Description';
};
annotate crm.ProductGroups with {
    name        @Common.Label : 'Name';
    description @Common.Label : 'Description';
};


annotate crm.Products with {
    
    mainCategory @(
        Common.Text            : mainCategory.name,
        Common.TextArrangement : #TextOnly,
        Common.ValueList       : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'MainCategories',
            Parameters     : [
                { $Type : 'Common.ValueListParameterInOut', LocalDataProperty : mainCategory_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' }
            ]
        }
    );

    subCategory @(
        Common.Text            : subCategory.name,
        Common.TextArrangement : #TextOnly,
        Common.ValueList       : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'SubCategories',
            Parameters     : [
                { $Type : 'Common.ValueListParameterInOut', LocalDataProperty : subCategory_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' },
                { $Type : 'Common.ValueListParameterIn', LocalDataProperty : mainCategory_ID, ValueListProperty : 'parent_ID' }
            ]
        }
    );

    category @( 
        Common.Text            : category.name,
        Common.TextArrangement : #TextOnly,
        Common.ValueList       : {
            $Type          : 'Common.ValueListType',
            CollectionPath : 'ProductGroups',
            Parameters     : [
                { $Type : 'Common.ValueListParameterInOut', LocalDataProperty : category_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' },
                { $Type : 'Common.ValueListParameterIn', LocalDataProperty : subCategory_ID, ValueListProperty : 'parent_ID' }
            ]
        }
    );
}
annotate crm.MainCategories with{
    ID @UI.Hidden : true;
}

annotate crm.SubCategories with{
    ID @UI.Hidden : true;
}
annotate crm.ProductGroups with{
    ID @UI.Hidden : true;
}

annotate crm.Products with @(
    UI.FieldGroup #ProductMediaUploader : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Value : content,     
                Label : 'Product Image File'
            }
        ]
    }
);


annotate crm.ProductImage with @(
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Value : content,       
            Label : 'Image Preview',
            @Core.MediaType : mediaType,
            @Core.ContentDisposition.Type: 'inline',
            @UI.IsImage : true
        }
    ]
);



annotate crm.ProductImage with @(
    UI.LineItem : [
        {
            $Type : 'UI.DataField',
            Value : content,       
            Label : 'Image Preview',
            @Core.MediaType : mediaType,
            @Core.ContentDisposition.Type: 'inline',
            @UI.IsImage : true
        }
    ]
);


annotate crm.Products with @(
    UI.Facets : [
        {
            $Type  : 'UI.CollectionFacet',
            ID     : 'ProductFormDashboard',
            Label  : 'Product Information Management',
            Facets : [
                {
                    $Type  : 'UI.ReferenceFacet',
                    ID     : 'DetailsSubFacet',
                    Label  : 'Specifications',
                    Target : '@UI.FieldGroup#GeneralProductDetails'
                },
                {
                    $Type  : 'UI.ReferenceFacet',
                    ID     : 'CategorySubFacet',
                    Label  : 'Taxonomy & Classifications', 
                    Target : '@UI.FieldGroup#ProductClassifications'
                },
                {
                    $Type  : 'UI.ReferenceFacet',
                    ID     : 'MediaSubFacet',
                    Label  : 'Product Media File Management',
                    Target : '@UI.FieldGroup#ProductMediaUploader'
                }
            ]

        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'ReviewsFacet',
            Label : 'Customer Reviews',
            Target: 'reviews/@UI.LineItem' 
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'ReviewsFacetPhotos',
            Label : 'Product Images',
            Target: 'images/@UI.LineItem' 
        }

    ]
);