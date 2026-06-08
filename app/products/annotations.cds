using CRMService as crm from '../../srv/service';

// ==========================================
// 1. GLOBAL PROPERTY ANNOTATIONS (Core Behaviours)
// ==========================================

annotate crm.Products with @(
    UI.HeaderInfo : {
        TypeName       : 'Product',
        TypeNamePlural : 'Products',
        Title          : {
            $Type : 'UI.DataField',
            Value : title,       // <--- This makes the Product Name the big main header title!
        },
        Description    : {
            $Type : 'UI.DataField',
            Value : desc,        // <--- This puts the Product Description right below it as a subtitle
        },
        ImageUrl       : content
    }
);

annotate crm.Products with {
    // Media configuration: Links the content to its dynamic mimetype
    content   @Core.MediaType : mediaType
              @Core.ContentDisposition.Type: 'inline'
              @UI.IsImage : true;  // This forces the content to render as an image in the Object Page header and as a thumbnail in the List Report rows
              
    mediaType @Core.IsMediaType: true;

    // Hardcoded currency setup for price displaying
    price     @Measures.ISOCurrency : 'USD';

    // Forces the Object Page input to become a numeric Step Input Picker
    stock     @HTML5.ControlHint : #StepInput
              @HTML5.StepInput.Step : 1
              @Common.Validation.Minimum : 0;
};

// ==========================================
// 2. MAIN LIST TABLE LAYOUT (List Report)
// ==========================================

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
            @UI.IsImageURL : true   // Forces it to render cleanly as a thumbnail image ONLY in the table rows
        },
        {
            $Type : 'UI.DataField',
            Value : stock,
            Label : 'Inventory Count'
        }
    ]
);

// ==========================================
// 3. OBJECT PAGE DETAIL VIEW GRID LAYOUT
// ==========================================

// Block A: Left Column Form (Text inputs)
annotate crm.Products with @(
    UI.FieldGroup #GeneralProductDetails : {
        $Type : 'UI.FieldGroupType',
        Data : [
            { $Type : 'UI.DataField', Value : title, Label : 'Product Name' },
            { $Type : 'UI.DataField', Value : price, Label : 'Unit Price' },
            { $Type : 'UI.DataField', Value : stock, Label : 'Inventory Count' }
        ]
    }
);
annotate crm.Products with @(
    UI.FieldGroup #ProductClassifications : {
        $Type : 'UI.FieldGroupType',
        Data : [
            
            { 
                $Type : 'UI.DataField', 
                Value : mainCategory_ID, // LEVEL 0 -> Points to Category Table
                Label : 'Department' 
            },
            { 
                $Type : 'UI.DataField', 
                Value : subCategory_ID,  // LEVEL 1 -> Points to SubCategory Table
                Label : 'Category' 
            },
            { 
                $Type : 'UI.DataField', 
                Value : category_ID,     // LEVEL 2 -> Points to ProductGroup Table
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

// annotate crm.Products with @(
//     // 1. When Department (mainCategory) changes, clear Category and Segment
//     Common.SideEffects #DepartmentChanged : {
//         SourceProperties : [ mainCategory_ID ],
//         TargetProperties : [ subCategory_ID, category_ID ] 
//     },
    
//     // 2. When Category (subCategory) changes, clear Segment
//     Common.SideEffects #CategoryChanged : {
//         SourceProperties : [ subCategory_ID ],
//         TargetProperties : [ category_ID ]
//     }
// );
annotate crm.Products with {
    
    // Target mainCategory_ID explicitly!
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

    // Target subCategory_ID explicitly!
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

    // Target category_ID explicitly!
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

// Block B: Right Column Form (Dedicated File Uploader slot)
annotate crm.Products with @(
    UI.FieldGroup #ProductMediaUploader : {
        $Type : 'UI.FieldGroupType',
        Data : [
            {
                $Type : 'UI.DataField',
                Value : content,     // Leaving ONLY content here turns it into an interactive File Upload/Drop zone
                Label : 'Product Image File'
            }
        ]
    }
);

// Main Layout Assembly: Packs Block A and Block B side-by-side into a beautiful grid dashboard
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
                    Label  : 'Taxonomy & Classifications', // This creates a distinct box with explicit spacing margins
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
        }

    ]
);