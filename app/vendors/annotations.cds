using CRMService as service from '../../srv/service';


annotate service.Vendors with @(
    UI.HeaderInfo : {
        TypeName       : 'Vendor',
        TypeNamePlural : 'Vendors',
        Title          : { $Type : 'UI.DataField', Value : name },
        Description    : { $Type : 'UI.DataField', Value : contact }
    },
    UI.LineItem:[
        {
            $Type  : 'UI.DataField',
            Label  : 'Vendor Name',
            Value : name
        },
        {
            $Type  : 'UI.DataField',
            Label  : 'Representative Name',
            Value : contact
        },
    ],
    UI.Facets : [
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Vendor Profile',
            Target : '@UI.FieldGroup#Profile'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Assigned Products',
            Target : 'products/@UI.LineItem'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Interactions with Customers',
            Target : 'interactions/@UI.LineItem'
        }
    ],
    UI.FieldGroup #Profile : {
        Data : [
            { $Type : 'UI.DataField', Value : email, Label : 'Email Address' },
            { $Type : 'UI.DataField', Value : address, Label : 'Headquarters' }
        ]
    }
);

annotate service.OrderItems with {
    product_content @(
        Core.MediaType : product_mediaType,  // 👈 Fixes the missing element error!
        Core.ContentDisposition.Filename : product_fileName
    );
};
annotate service.Interactions with @(
    // UI.HeaderInfo : {
    //     TypeName       : 'Assigned Ticket',
    //     TypeNamePlural : 'Assigned Tickets',
    //     Title          : { $Type : 'UI.DataField', Value : caseNumber }
    // },
    UI.LineItem : [
        { $Type : 'UI.DataField', Value : caseNumber, Label : 'Case Number', @UI.Importance : #High },
        { $Type : 'UI.DataField', Value : title, Label : 'Subject', @UI.Importance : #High },
        { $Type : 'UI.DataField', Value : status_code, Label : 'Status', @UI.Importance : #High },
        { $Type : 'UI.DataField', Value : priority_code, Label : 'Priority', @UI.Importance : #Medium },
        { $Type : 'UI.DataField', Value : summary, Label : 'Description', @UI.Importance : #Low }
    ],
    // UI.Facets : [
    //     {
    //         $Type  : 'UI.ReferenceFacet',
    //         Label  : 'Ticket Details',
    //         Target : '@UI.FieldGroup#TicketDetails'
    //     },
    //     {
    //         $Type  : 'UI.ReferenceFacet',
    //         Label  : 'Correspondence Logs',
    //         Target : 'logs/@UI.LineItem' // Links directly to the Vendor's chat facet
    //     }
    // ],
    UI.FieldGroup #TicketDetails : {
        Data : [
            { $Type : 'UI.DataField', Value : caseNumber, Label : 'Case Number' },
            { $Type : 'UI.DataField', Value : title, Label : 'Subject' },
            { $Type : 'UI.DataField', Value : summary, Label : 'Customer Issue Summary' },
            { $Type : 'UI.DataField', Value : resolution, Label : 'Your Resolution / Reply' }
        ]
    }
);



// annotate service.InteractionLogs with @(
//     UI.LineItem : [
//         { 
//             $Type : 'UI.DataField', 
//             Value : author, 
//             Label : 'By', 
//             @UI.Importance : #High 
//         },
//         { 
//             $Type : 'UI.DataField', 
//             Value : text, 
//             Label : 'Message', 
//             @UI.Importance : #High 
//         },
//         { 
//             $Type : 'UI.DataField', 
//             Value : createdAt, 
//             Label : 'Timestamp', 
//             @UI.Importance : #Medium 
//         }
//     ]
// );

// ==========================================
// 4. METADATA MASKING (COLUMN-LEVEL SECURITY)
// ==========================================
annotate service.InteractionLogs with {
    // This absolutely hides the "Private Note" indicator field from Bob the Vendor's UI components
    isPrivate @UI.Hidden: true;
};
