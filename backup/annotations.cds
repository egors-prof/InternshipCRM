// using CRMService as service from '../../srv/service';
// annotate CRMService.Products with @(
//     // 1. Header Info: Adding ImageUrl here puts the preview picture at the top of the details page!
//     UI.HeaderInfo : {
//         TypeName       : 'Product',
//         TypeNamePlural : 'Products',
//         ImageUrl       : content, // <-- THIS ACTIVATES THE PREVIEW
//         Title          : { $Type : 'UI.DataField', Value : title },
//         Description    : { $Type : 'UI.DataField', Value : price }
//     },
    
//     // 2. Line Item: Adding image.content here creates a thumbnail column in your main table
//     UI.LineItem : [
//         { 
//             $Type : 'UI.DataField', 
//             Value : content, // <-- THUMBNAIL IN THE GRID
//             Label : 'Preview', 
//             @UI.Importance : #High 
//         },
//         { 
//             $Type : 'UI.DataField', 
//             Value : title, 
//             Label : 'Product Name', 
//             @UI.Importance : #High 
//         },
//         { 
//             $Type : 'UI.DataField', 
//             Value : price, 
//             Label : 'Unit Price', 
//             @UI.Importance : #High 
//         },
//         { 
//             $Type : 'UI.DataField', 
//             Value : stock, 
//             Label : 'Current Stock', 
//             @UI.Importance : #Medium 
//         },
        
//     ],

//     UI.Facets : [
//         {
//             $Type  : 'UI.ReferenceFacet',
//             Label  : 'Product Details',
//             Target : '@UI.FieldGroup#Details'
//         }
//     ],
    
//     UI.FieldGroup #Details : {
//         Data : [
//             { $Type : 'UI.DataField', Value : title, Label : 'Product Name' },
//             { $Type : 'UI.DataField', Value : content, Label : 'Image Preview' },
//             { $Type : 'UI.DataField', Value : desc, Label : 'Description' },
//             { $Type : 'UI.DataField', Value : price, Label : 'Unit Price' },
//             { $Type : 'UI.DataField', Value : stock, Label : 'Inventory Count' },
           
//         ]
//     }
// );

// annotate service.Products with {
//     content @UI.IsImage : true;
// };
// annotate service.Products with {
//     category @Common.ValueList : {
//         $Type : 'Common.ValueListType',
//         CollectionPath : 'ProductGroups',
//         Parameters : [
//             {
//                 $Type : 'Common.ValueListParameterInOut',
//                 LocalDataProperty : category_ID,
//                 ValueListProperty : 'ID',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'name',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'description',
//             },
//         ],
//     }
// };

// annotate service.Products with {
//     subCategory @Common.ValueList : {
//         $Type : 'Common.ValueListType',
//         CollectionPath : 'SubCategories',
//         Parameters : [
//             {
//                 $Type : 'Common.ValueListParameterInOut',
//                 LocalDataProperty : subCategory_ID,
//                 ValueListProperty : 'ID',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'name',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'description',
//             },
//         ],
//     }
// };

// annotate service.Products with {
//     mainCategory @Common.ValueList : {
//         $Type : 'Common.ValueListType',
//         CollectionPath : 'MainCategories',
//         Parameters : [
//             {
//                 $Type : 'Common.ValueListParameterInOut',
//                 LocalDataProperty : mainCategory_ID,
//                 ValueListProperty : 'ID',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'name',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'description',
//             },
//         ],
//     }
// };

// annotate service.Products with {
//     vendor @Common.ValueList : {
//         $Type : 'Common.ValueListType',
//         CollectionPath : 'Vendors',
//         Parameters : [
//             {
//                 $Type : 'Common.ValueListParameterInOut',
//                 LocalDataProperty : vendor_ID,
//                 ValueListProperty : 'ID',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'name',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'contact',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'email',
//             },
//             {
//                 $Type : 'Common.ValueListParameterDisplayOnly',
//                 ValueListProperty : 'address',
//             },
//         ],
//     }
// };

