sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"vendors/test/integration/pages/VendorsList",
	"vendors/test/integration/pages/VendorsObjectPage"
], function (JourneyRunner, VendorsList, VendorsObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('vendors') + '/test/flp.html#app-preview',
        pages: {
			onTheVendorsList: VendorsList,
			onTheVendorsObjectPage: VendorsObjectPage
        },
        async: true
    });

    return runner;
});

