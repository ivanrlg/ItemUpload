codeunit 53103 ProcessItemJson
{
    //Method that is responsible for reading the Json Array, obtaining the values, 
    //checking if it exists in the configuration tables and finally creating the related records.
    procedure ProcessItem(var ArrayJSONManagement: Codeunit "JSON Management"; var i: Integer; var Proccesed: Integer)
    var
        Item: Record Item;
        TaxGroup: Record "Tax Group";
        InventoryPostingGroup: Record "Inventory Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        ObjectJSONManagement: Codeunit "JSON Management";
        VariantCode, BaseUnitofMeasure : Code[10];
        CUSTOMERGROUP, DEPARTMENT, Barcode, ItemCategoryCode, TaxGroupCode : Code[20];
        InventoryPostingGroupCode, GenProdPostingGroupCode : Code[20];
        UnitPrice: Decimal;
        CostingMethod: Enum "Costing Method";
        Color, Height, Width : Text;
        FieldText: Text;
        ItemJsonObject: Text;
        Style: Text;
        Description: Text[100];
        VariantDescription: Text[100];
        ErrorFlag: Boolean;
    begin
        ErrorFlag := false;

        ArrayJSONManagement.GetObjectFromCollectionByIndex(ItemJsonObject, i);
        ObjectJSONManagement.InitializeObject(ItemJsonObject);

        Item.Init();

        ObjectJSONManagement.GetStringPropertyValueByName('No', FieldText);
        Item.Validate("No.", CopyStr(FieldText.ToUpper(), 1, MaxStrLen(Item."No.")));

        ObjectJSONManagement.GetStringPropertyValueByName('Variant Code', FieldText);
        VariantCode := CopyStr(FieldText.ToUpper(), 1, 10);

        ObjectJSONManagement.GetStringPropertyValueByName('Variant Description', FieldText);
        VariantDescription := CopyStr(FieldText.ToUpper(), 1, 100);

        ObjectJSONManagement.GetStringPropertyValueByName('Description', FieldText);
        Description := CopyStr(FieldText.ToUpper(), 1, MaxStrLen(Item.Description));
        Item.Validate(Description, Description);

        ObjectJSONManagement.GetStringPropertyValueByName('Base Unit of Measure', FieldText);
        BaseUnitofMeasure := CopyStr(FieldText.ToUpper(), 1, MaxStrLen(Item."Base Unit of Measure"));

        ObjectJSONManagement.GetStringPropertyValueByName('Costing Method', FieldText);
        if FieldText <> '' then begin
            Evaluate(CostingMethod, FieldText);
            Item.Validate("Costing Method", CostingMethod);
        end else begin
            Item.Validate("Costing Method", CostingMethod::FIFO);
        end;

        //ErrorInfo: Here we create a use case, if the information does not exist in the related table,
        //we queue the error with the pertinent details.
        ObjectJSONManagement.GetStringPropertyValueByName('Tax Group Code', FieldText);
        TaxGroupCode := CopyStr(FieldText.ToUpper(), 1, MaxStrLen(Item."Tax Group Code"));

        if TaxGroup.Get(TaxGroupCode) then begin
            Item.Validate("Tax Group Code", TaxGroupCode);
        end else begin
            Error(ErrorInfo.Create(StrSubstNo('Error in %1: The %2: %3 does not exist in the table %4',
                                  Item."No.",
                                  Item.FieldCaption(Item."Tax Group Code"),
                                  TaxGroupCode,
                                  TaxGroup.TableCaption()
                                  ), true, TaxGroup, TaxGroup.FieldNo(Code)));
            ErrorFlag := true;
        end;


        //ErrorInfo: Here we create a use case, if the information does not exist in the related table,
        //we queue the error with the pertinent details.
        ObjectJSONManagement.GetStringPropertyValueByName('Inventory Posting Group', FieldText);
        InventoryPostingGroupCode := CopyStr(FieldText.ToUpper(), 1, MaxStrLen(Item."Inventory Posting Group"));

        if InventoryPostingGroup.Get(InventoryPostingGroupCode) then begin
            Item.Validate("Inventory Posting Group", InventoryPostingGroupCode);
        end else begin
            Error(ErrorInfo.Create(StrSubstNo('Error in %1: The %2: %3 does not exist in the table %4',
                                  Item."No.",
                                  Item.FieldCaption(Item."Inventory Posting Group"),
                                  InventoryPostingGroupCode,
                                  InventoryPostingGroup.TableCaption()
                                  ), true, InventoryPostingGroup, InventoryPostingGroup.FieldNo(Code)));
            ErrorFlag := true;
        end;

        //ErrorInfo: Here we create a use case, if the information does not exist in the related table,
        //we queue the error with the pertinent details.
        ObjectJSONManagement.GetStringPropertyValueByName('Gen. Prod. Posting Group', FieldText);
        GenProdPostingGroupCode := CopyStr(FieldText.ToUpper(), 1, MaxStrLen(Item."Gen. Prod. Posting Group"));

        if GenProductPostingGroup.Get(GenProdPostingGroupCode) then begin
            Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        end else begin
            Error(ErrorInfo.Create(StrSubstNo('Error in %1: The %2: %3 does not exist in the table %4',
                                              Item."No.",
                                              Item.FieldCaption(Item."Gen. Prod. Posting Group"),
                                              GenProdPostingGroupCode,
                                              GenProductPostingGroup.TableCaption()),
                                              true, GenProductPostingGroup, InventoryPostingGroup.FieldNo(Code)));
            ErrorFlag := true;
        end;


        ObjectJSONManagement.GetStringPropertyValueByName('Unit Price', FieldText);
        if FieldText <> '' then begin
            Evaluate(UnitPrice, FieldText);
            Item.Validate("Unit Price", UnitPrice);
        end else begin
            Item.Validate("Unit Price", 0);
        end;

        ObjectJSONManagement.GetStringPropertyValueByName('DEPARTMENT', FieldText);
        DEPARTMENT := CopyStr(FieldText.ToUpper(), 1, 20);

        ObjectJSONManagement.GetStringPropertyValueByName('CUSTOMERGROUP', FieldText);
        CUSTOMERGROUP := CopyStr(FieldText.ToUpper(), 1, 20);

        ObjectJSONManagement.GetStringPropertyValueByName('Color', FieldText);
        Color := FieldText;

        ObjectJSONManagement.GetStringPropertyValueByName('Width', FieldText);
        Width := FieldText;

        ObjectJSONManagement.GetStringPropertyValueByName('Height', FieldText);
        Height := FieldText;

        if ErrorFlag then
            exit;

        if not Item.Insert() then begin
            if not Item.Modify() then begin
                Error(ErrorInfo.Create(StrSubstNo('Item No %1, can not be inserted', Item."No."), true, Item, Item.FieldNo("No.")));
                exit;
            end;
        end;

        //Once the Item has been created or updated, we create the aforementioned related records.
        ManageItemUnitOfMeasure(Item, BaseUnitofMeasure);
        ManageItemAttribute(Item, Color, Width, Height);
        ManageItemIdentifier(Item, Barcode, VariantCode);
        ManageVariant(Item, VariantCode, VariantDescription);
        ManageDimensions(Item, DEPARTMENT, CUSTOMERGROUP);
        ManageSKU(Item, VariantCode);

        Proccesed += 1;
    end;

    local procedure ManageItemUnitOfMeasure(var Item: Record Item; BaseUnitofMeasure: Code[10])
    var
        ItemTemp: Record Item;
    begin
        if ItemTemp.Get(Item."No.") then begin
            ItemTemp.Validate("Base Unit of Measure", BaseUnitofMeasure);
            ItemTemp.Modify();
        end;
    end;

    local procedure ManageItemAttribute(var Item: Record Item; Color: Text; Width: Text; Height: Text)
    var
        ItemAttributeValueList: Page 5734;
        ItemAttributeID: Integer;
        ItemAttributeValueID: Integer;
    begin
        if Color <> '' then begin
            GetAttributesIds('Color', Color, ItemAttributeID, ItemAttributeValueID);
            MapItemAttibute(Item, ItemAttributeID, ItemAttributeValueID);
        end;

        if Width <> '' then begin
            GetAttributesIds('Width', Width, ItemAttributeID, ItemAttributeValueID);
            MapItemAttibute(Item, ItemAttributeID, ItemAttributeValueID);
        end;

        if Height <> '' then begin
            GetAttributesIds('Height', Height, ItemAttributeID, ItemAttributeValueID);
            MapItemAttibute(Item, ItemAttributeID, ItemAttributeValueID);
        end;
    end;

    local procedure GetAttributesIds(Name: Text[250]; Value: Text[250]; var ItemAttributeID: Integer; var ItemAttributeValueID: Integer)
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttribute.Reset();
        ItemAttribute.SetRange(Name, Name);
        if not ItemAttribute.FindLast() then begin
            ItemAttribute.Init();
            ItemAttribute.Validate(Name, Name);
            ItemAttribute.Insert();
        end;

        ItemAttributeValue.Reset();
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetRange(Value, Value);
        if not ItemAttributeValue.FindLast() then begin
            ItemAttributeValue.Init();
            ItemAttributeValue.Validate("Attribute ID", ItemAttribute.ID);
            ItemAttributeValue.Validate(Value, Value);
            ItemAttributeValue.Insert();
        end;

        ItemAttributeValueID := ItemAttributeValue.ID;
        ItemAttributeID := ItemAttributeValue."Attribute ID";
    end;

    local procedure MapItemAttibute(var Item: Record Item; var ItemAttributeID: Integer; var ItemAttributeValueID: Integer)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        Clear(ItemAttributeValueMapping);

        if not ItemAttributeValueMapping.Get(Database::Item, Item."No.", ItemAttributeID) then begin
            ItemAttributeValueMapping.Init();
            ItemAttributeValueMapping.Validate("No.", Item."No.");
            ItemAttributeValueMapping."Item Attribute ID" := ItemAttributeID;
            ItemAttributeValueMapping."Item Attribute Value ID" := ItemAttributeValueID;
            ItemAttributeValueMapping.Validate("Table ID", Database::Item);
            ItemAttributeValueMapping.Insert();
        end;
    end;


    local procedure ManageDimensions(var Item: Record Item; DEPARTMENT: Code[20]; CUSTOMERGROUP: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        //DEPARTMENT
        if DEPARTMENT <> '' then begin
            DefaultDimension.Reset();
            DefaultDimension.SetRange("Table ID", 27);
            DefaultDimension.SetRange("No.", Item."No.");
            DefaultDimension.SetFilter("Dimension Code", 'DEPARTMENT');
            if not DefaultDimension.FindLast() then begin

                DefaultDimension.Init();
                DefaultDimension."Table ID" := 27;
                DefaultDimension."No." := Item."No.";
                DefaultDimension."Dimension Code" := 'DEPARTMENT';
                DefaultDimension."Dimension Value Code" := DEPARTMENT;
                DefaultDimension."Value Posting" := "Default Dimension Value Posting Type"::"Code Mandatory";
                DefaultDimension.Insert();

            end else begin
                DefaultDimension."Dimension Value Code" := DEPARTMENT;
                DefaultDimension."Value Posting" := "Default Dimension Value Posting Type"::"Code Mandatory";
                DefaultDimension.Modify();
            end;
        end;

        //CUSTOMERGROUP
        if CUSTOMERGROUP <> '' then begin
            DefaultDimension.Reset();
            DefaultDimension.SetRange("Table ID", 27);
            DefaultDimension.SetRange("No.", Item."No.");
            DefaultDimension.SetFilter("Dimension Code", 'CUSTOMERGROUP');
            if not DefaultDimension.FindLast() then begin

                DefaultDimension.Init();
                DefaultDimension."Table ID" := 27;
                DefaultDimension."No." := Item."No.";
                DefaultDimension."Dimension Code" := 'CUSTOMERGROUP';
                DefaultDimension."Dimension Value Code" := CUSTOMERGROUP;
                DefaultDimension."Value Posting" := "Default Dimension Value Posting Type"::"Code Mandatory";
                DefaultDimension.Insert();

            end else begin
                DefaultDimension."Dimension Value Code" := CUSTOMERGROUP;
                DefaultDimension."Value Posting" := "Default Dimension Value Posting Type"::"Code Mandatory";
                DefaultDimension.Modify();
            end;
        end;
    end;

    local procedure ManageVariant(var Item: Record Item; VariantCode: Code[10]; Description: Text[100])
    var
        ItemVariant: Record "Item Variant";
    begin
        if VariantCode = '' then
            exit;

        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.SetRange(Code, VariantCode);
        if not ItemVariant.FindLast() then begin
            ItemVariant.Init();
            ItemVariant."Item No." := Item."No.";
            ItemVariant.Code := VariantCode;
            ItemVariant.Description := Description;
            ItemVariant.Insert();
        end else begin
            ItemVariant."Item No." := Item."No.";
            ItemVariant.Code := VariantCode;
            ItemVariant.Description := Description;
            ItemVariant.Modify();
        end;
    end;

    local procedure ManageItemIdentifier(var Item: Record Item; Barcode: Code[20]; VariantCode: Code[10])
    var
        ItemIdentifier: Record "Item Identifier";
    begin
        if Barcode = '' then
            exit;

        if not ItemIdentifier.Get(Barcode) then begin
            ItemIdentifier.Init();
            ItemIdentifier."Item No." := Item."No.";
            ItemIdentifier."Variant Code" := VariantCode;
            ItemIdentifier.Code := Barcode;
            ItemIdentifier.Insert();
        end else begin
            ItemIdentifier."Item No." := Item."No.";
            ItemIdentifier."Variant Code" := VariantCode;
            ItemIdentifier.Code := Barcode;
            ItemIdentifier.Modify();
        end;
    end;

    local procedure ManageSKU(var Item: Record Item; VariantCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        if VariantCode = '' then
            exit;

        StockkeepingUnit.Reset();
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.SetRange("Variant Code", VariantCode);
        if StockkeepingUnit.FindLast() then begin
            StockkeepingUnit.CopyFromItem(Item);
            StockkeepingUnit."Variant Code" := VariantCode;
            StockkeepingUnit.Modify();
        end else begin
            StockkeepingUnit.Init();
            StockkeepingUnit."Item No." := Item."No.";
            StockkeepingUnit.CopyFromItem(Item);
            StockkeepingUnit."Variant Code" := VariantCode;
            StockkeepingUnit.Insert();
        end;
    end;
}
