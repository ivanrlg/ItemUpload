pageextension 53100 Items extends "Item list"
{
    actions
    {
        addafter("Item Refe&rences")
        {
            action(Test)
            {
                ApplicationArea = All;
                PromotedIsBig = true;
                Promoted = true;
                Image = Import;
                trigger OnAction()
                var
                    Request: text;
                    ProcessMethod: Codeunit ProcessMethod;
                begin
                    Request := '[ {"No": "ITEM1","Variant Code": "Red2010","Variant Description": "Variant Description 1","Description": "Item Description 1","Base Unit of Measure": "EA","Barcode": "XXXXXX000001","Unit Price": 100,"Color": "Red","Width": 20,"Height": 10,"DEPARTMENT": "ADM","CUSTOMERGROUP": "LARGE","Tax Group Code": "NONTAXABLE","Inventory Posting Group": "RESALE","Gen. Prod. Posting Group": "RETAIL" }]';
                    ProcessMethod.Request(Request);
                end;
            }
        }
    }
}
