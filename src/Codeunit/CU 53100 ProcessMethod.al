codeunit 53100 ProcessMethod
{
    procedure Request(jsonText: Text) Response: Text
    var
        JsonObject: JsonObject;
        JToken, ParamsJToken, ProcessMethodJToken : JsonToken;
        ProcessMethod: text;
    begin
        if (jsonText = '') then
            Error('Json is empty!');

        exit(InsertItem(jsonText));
    end;

    procedure Ping(): Text
    begin
        exit('Pong');
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure InsertItem(JsonObjectText: Text): Text
    var
        ArrayJSONManagement: Codeunit "JSON Management";
        i: Integer;
        TotalItems, TotalErrors, TotalProccesed : Integer;
        tableNo: Integer;
        Output: Text;
        ProcessItem: Codeunit ProcessItemJson;
        Errors: List of [ErrorInfo];
        JsonArray: JsonArray;
        ErrorInfo: ErrorInfo;
        JsonObject: JsonObject;
        ErrorsTemporary: Record "Error Message" temporary;
    begin
        ArrayJSONManagement.InitializeCollection(JsonObjectText);
        TotalItems := ArrayJSONManagement.GetCollectionCount();

        for i := 0 to TotalItems - 1 do begin
            ProcessItem.ProcessItem(ArrayJSONManagement, i, TotalProccesed);
        end;

        if HasCollectedErrors then begin

            Errors := GetCollectedErrors();

            TotalErrors := Errors.Count;

            foreach ErrorInfo in Errors do begin
                JsonObject.Add('Message', ErrorInfo.Message);
                //JsonObject.Add('DetailedMessage', ErrorInfo.DetailedMessage);
                JsonObject.Add('TableId', ErrorInfo.TableId);
                JsonObject.Add('FieldNo', ErrorInfo.FieldNo);
                JsonObject.Add('ErrorType', format(ErrorInfo.ErrorType));
                JsonArray.Add(JsonObject);
                Clear(JsonObject);

                ErrorsTemporary.ID := ErrorsTemporary.ID + 1;
                ErrorsTemporary.Description := ErrorInfo.Message;
                ErrorsTemporary.Validate("Record ID", ErrorInfo.RecordId);
                ErrorsTemporary.Insert();
            end;

            ClearCollectedErrors();

            if GuiAllowed then
                Page.Run(page::"Error Messages", ErrorsTemporary);
        end;

        JsonObject.Add('Processed Items', TotalProccesed);
        JsonObject.Add('Not Processed Items', TotalItems - TotalProccesed);
        JsonObject.Add('Errors', JsonArray);
        JsonObject.WriteTo(Output);
        exit(Output);
    end;
}
