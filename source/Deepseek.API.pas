unit Deepseek.API;

{-------------------------------------------------------------------------------

      Github repository :  https://github.com/MaxiDonkey/DelphiDeepseek
      Visit the Github repository for the documentation and use examples

 ------------------------------------------------------------------------------}

interface

uses
  System.Classes, System.Net.HttpClient, System.Net.URLClient, System.Net.Mime,
  System.JSON, Deepseek.Errors, Deepseek.API.Params, System.SysUtils, Deepseek.HttpClient,
  Deepseek.HttpClient.Intf, Deepseek.Exception, Deepseek.Monitoring;

type
  TDeepseekConfiguration = class
  const
      URL_BASE = 'https://api.deepseek.com';
  strict private
    class var FLocalUrlBase: string;
  private
    FAPIKey: string;
    FBaseUrl: string;
    FLMStudio: Boolean;
    procedure SetAPIKey(const Value: string);
    procedure SetBaseUrl(const Value: string);
  public
    constructor Create;
    procedure APICheck;
    property APIKey: string read FAPIKey write SetAPIKey;
    property BaseUrl: string read FBaseUrl write SetBaseUrl;
    property LMStudio: Boolean read FLMStudio write FLMStudio;
    class property LocalUrlBase: string read FLocalUrlBase write FLocalUrlBase;
  end;

  TApiHttpHandler = class(TDeepseekConfiguration)
  private
    FCustomHeaders: TNetHeaders;
    procedure SetCustomHeaders(const Value: TNetHeaders);
  protected
    FClientHttp: IHttpClientAPI;
    function GetClientHttp: IHttpClientAPI;
    function GetHeaders: TNetHeaders;
    function BuildHeaders: TNetHeaders;
    function BuildUrl(const Endpoint: string): string;
  public
    function Client: IHttpClientAPI;
    property ClientHttp: IHttpClientAPI read GetClientHttp;
    property CustomHeaders: TNetHeaders read FCustomHeaders write SetCustomHeaders;
  end;

  TDeepseekAPI = class(TApiHttpHandler)
  private
    procedure RaiseError(Code: Int64; Error: TErrorCore);
    procedure DeserializeErrorData(const Code: Int64; const ResponseText: string);
    function Deserialize<T: class, constructor>(const Code: Int64; const ResponseText: string): T; overload;
  public
    function Get<TResult: class, constructor>(const Path: string): TResult; overload;
    procedure GetFile(const Path: string; Response: TStream); overload;
    function Delete<TResult: class, constructor>(const Path: string): TResult; overload;
    function Post<TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>; Response: TStringStream; Event: TReceiveDataCallback = nil): Boolean; overload;
    function Post<TResult: class, constructor; TParams: TJSONParam>(const Path: string; ParamProc: TProc<TParams>): TResult; overload;
    function Post<TResult: class, constructor>(const Path: string): TResult; overload;
    function PostForm<TResult: class, constructor; TParams: TMultipartFormData, constructor>(const Path: string; ParamProc: TProc<TParams>): TResult; overload;
    function PostForm<TResult: class, constructor; TParams: TMultipartFormData, constructor>(const Path: string; ParamProc: TProc<TParams>;
      var ResponseHeader: TNetHeaders): TResult; overload;
  public
    constructor Create(const LocalLMS: Boolean = False); overload;
    class function Parse<T: class, constructor>(const Value: string): T;
  end;

  TDeepseekAPIRoute = class
  private
    FAPI: TDeepseekAPI;
    procedure SetAPI(const Value: TDeepseekAPI);
  protected
    procedure HeaderCustomize; virtual;
  public
    property API: TDeepseekAPI read FAPI write SetAPI;
    constructor CreateRoute(AAPI: TDeepseekAPI); reintroduce;
  end;

implementation

uses
  System.StrUtils, REST.Json, System.NetConsts;

constructor TDeepseekAPI.Create(const LocalLMS: Boolean);
begin
  inherited Create;
  FAPIKey := EmptyStr;
  FLMStudio := LocalLMS;
  if FLMStudio then
    FBaseUrl := TDeepseekAPI.LocalUrlBase
  else
    FBaseUrl := URL_BASE;
  FClientHttp := THttpClientAPI.CreateInstance(APICheck);
end;

function TDeepseekAPI.Post<TResult, TParams>(const Path: string; ParamProc: TProc<TParams>): TResult;
var
  Response: TStringStream;
  Params: TParams;
  Code: Integer;
begin
  Monitoring.Inc;
  Response := TStringStream.Create('', TEncoding.UTF8);
  Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    Code := Client.Post(BuildUrl(Path), Params.JSON, Response, BuildHeaders, nil);
    Result := Deserialize<TResult>(Code, Response.DataString)
  finally
    Params.Free;
    Response.Free;
    Monitoring.Dec;
  end;
end;

function TDeepseekAPI.Post<TParams>(const Path: string; ParamProc: TProc<TParams>; Response: TStringStream; Event: TReceiveDataCallback): Boolean;
var
  Params: TParams;
  Code: Integer;
begin
  Monitoring.Inc;
  Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    Code := Client.Post(BuildUrl(Path), Params.JSON, Response, BuildHeaders, Event);
    case Code of
      200..299:
        Result := True;
    else
      Result := False;
    end;
  finally
    Params.Free;
    Monitoring.Dec;
  end;
end;

function TDeepseekAPI.Post<TResult>(const Path: string): TResult;
var
  Response: TStringStream;
  Code: Integer;
begin
  Monitoring.Inc;
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Code := Client.Post(BuildUrl(Path), Response, BuildHeaders);
    Result := Deserialize<TResult>(Code, Response.DataString);
  finally
    Response.Free;
    Monitoring.Dec;
  end;
end;

function TDeepseekAPI.Delete<TResult>(const Path: string): TResult;
var
  Response: TStringStream;
  Code: Integer;
begin
  Monitoring.Inc;
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Code := Client.Delete(BuildUrl(Path), Response, BuildHeaders);
    Result := Deserialize<TResult>(Code, Response.DataString);
  finally
    Response.Free;
    Monitoring.Dec;
  end;
end;

function TDeepseekAPI.PostForm<TResult, TParams>(const Path: string;
  ParamProc: TProc<TParams>; var ResponseHeader: TNetHeaders): TResult;
begin
  Monitoring.Inc;
  var Response := TStringStream.Create('', TEncoding.UTF8);
  var Params := TParams.Create;
  try
    if Assigned(ParamProc) then
      ParamProc(Params);
    var Code := Client.Post(BuildUrl(Path), Params, Response, ResponseHeader);
    Result := Deserialize<TResult>(Code, Response.DataString);
  finally
    Params.Free;
    Response.Free;
    Monitoring.Dec;
  end;
end;

function TDeepseekAPI.PostForm<TResult, TParams>(const Path: string; ParamProc: TProc<TParams>): TResult;
var
  ResponseHeader: TNetHeaders;
begin
  Result := PostForm<TResult, TParams>(Path, ParamProc, ResponseHeader);
end;

function TDeepseekAPI.Get<TResult>(const Path: string): TResult;
var
  Response: TStringStream;
  Code: Integer;
begin
  Monitoring.Inc;
  CustomHeaders := [TNetHeader.Create('accept', 'application/json')];
  Response := TStringStream.Create('', TEncoding.UTF8);
  try
    Code := Client.Get(BuildUrl(Path), Response, GetHeaders);
    Result := Deserialize<TResult>(Code, Response.DataString);
  finally
    Response.Free;
    Monitoring.Dec;
  end;
end;

procedure TDeepseekAPI.GetFile(const Path: string; Response: TStream);
var
  Code: Integer;
  Strings: TStringStream;
begin
  Monitoring.Inc;
  try
    Code := Client.Get(BuildUrl(Path), Response, GetHeaders);
    case Code of
      200..299:
        ; {success}
    else
      Strings := TStringStream.Create;
      try
        Response.Position := 0;
        Strings.LoadFromStream(Response);
        DeserializeErrorData(Code, Strings.DataString);
      finally
        Strings.Free;
      end;
    end;
  finally
    Monitoring.Dec;
  end;
end;

procedure TDeepseekAPI.RaiseError(Code: Int64; Error: TErrorCore);
begin
  case Code of
    {--- Client Error Codes }
    400:
      raise TDeepseekExceptionInvalidFormatError.Create(Code, Error);
    401:
      raise TDeepseekExceptionAuthenticationFailsError.Create(Code, Error);
    402:
      raise TDeepseekExceptionInsufficientBalanceError.Create(Code, Error);
    422:
      raise TDeepseekExceptionInvalidParametersError.Create(Code, Error);
    429:
      raise TDeepseekExceptionRateLimitReachedError.Create(Code, Error);
    {--- Server Error Codes }
    500:
      raise TDeepseekExceptionServerError.Create(Code, Error);
    503:
      raise TDeepseekExceptionServerOverloadeError.Create(Code, Error);
  else
    raise TDeepseekException.Create(Code, Error);
  end;
end;

class function TDeepseekAPI.Parse<T>(const Value: string): T;
begin
  Result := TJson.JsonToObject<T>(Value);

  {--- Add JSON response if class inherits from TJSONFingerprint class. }
  if Assigned(Result) and T.InheritsFrom(TJSONFingerprint) then
    begin
      var JSONValue := TJSONObject.ParseJSONValue(Value);
      try
        (Result as TJSONFingerprint).JSONResponse := JSONValue.Format();
      finally
        JSONValue.Free;
      end;
    end;
end;

procedure TDeepseekAPI.DeserializeErrorData(const Code: Int64; const ResponseText: string);
var
  Error: TErrorCore;
begin
  Error := nil;
  try
    try
      Error := TJson.JsonToObject<TError>(ResponseText);
    except
      Error := nil;
    end;
    if Assigned(Error) then
      RaiseError(Code, Error)
  finally
    if Assigned(Error) then
      Error.Free;
  end;
end;

function TDeepseekAPI.Deserialize<T>(const Code: Int64; const ResponseText: string): T;
begin
  Result := nil;
  case Code of
    200..299:
      try
        Result := Parse<T>(ResponseText);
      except
        FreeAndNil(Result);
      end;
  else
    DeserializeErrorData(Code, ResponseText);
  end;
  if not Assigned(Result) then
    raise TDeepseekExceptionInvalidResponse.Create(Code, 'Empty or invalid response');
end;

{ TDeepseekAPIRoute }

constructor TDeepseekAPIRoute.CreateRoute(AAPI: TDeepseekAPI);
begin
  inherited Create;
  FAPI := AAPI;
end;

procedure TDeepseekAPIRoute.HeaderCustomize;
begin

end;

procedure TDeepseekAPIRoute.SetAPI(const Value: TDeepseekAPI);
begin
  FAPI := Value;
end;

{ TDeepseekConfiguration }

procedure TDeepseekConfiguration.APICheck;
begin
  if FLMStudio then
    begin
      if FBaseUrl.IsEmpty then
        raise TDeepseekExceptionAPI.Create('Invalid LM Studio base URL.');
      Exit;
    end;

  if FAPIKey.IsEmpty or FBaseUrl.IsEmpty then
    raise TDeepseekExceptionAPI.Create('Invalid API key or base URL.');
end;

constructor TDeepseekConfiguration.Create;
begin
  inherited;
  FAPIKey := EmptyStr;
  FBaseUrl := URL_BASE;
end;

procedure TDeepseekConfiguration.SetAPIKey(const Value: string);
begin
  FAPIKey := Value;
end;

procedure TDeepseekConfiguration.SetBaseUrl(const Value: string);
begin
  FBaseUrl := Value;
end;

{ TApiHttpHandler }

function TApiHttpHandler.BuildHeaders: TNetHeaders;
begin
  Result := GetHeaders + [TNetHeader.Create('Content-Type', 'application/json')];
end;

function TApiHttpHandler.BuildUrl(const Endpoint: string): string;
begin
  Result := FBaseUrl.TrimRight(['/']) + '/' + Endpoint.TrimLeft(['/']);
end;

function TApiHttpHandler.Client: IHttpClientAPI;
begin
  Result := THttpClientAPI.CreateInstance(APICheck);
  Result.SendTimeOut := ClientHttp.SendTimeOut;
  Result.ConnectionTimeout := ClientHttp.ConnectionTimeout;
  Result.ResponseTimeout := ClientHttp.ResponseTimeout;
  var Proxy := ClientHttp.ProxySettings;
  Result.ProxySettings := TProxySettings.Create(Proxy.Host, Proxy.Port, Proxy.UserName, Proxy.Password, Proxy.Scheme);
end;

function TApiHttpHandler.GetClientHttp: IHttpClientAPI;
begin
  Result := FClientHttp;
end;

function TApiHttpHandler.GetHeaders: TNetHeaders;
begin
  if FLMStudio then
    begin
      Exit(FCustomHeaders);
    end;

  Result :=
    [TNetHeader.Create('authorization', 'Bearer ' + FAPIKey)] +
    FCustomHeaders;
end;

procedure TApiHttpHandler.SetCustomHeaders(const Value: TNetHeaders);
begin
  FCustomHeaders := Value;
end;

initialization
  TDeepseekAPI.LocalUrlBase := 'http://127.0.0.1:1234/v1';
end.

