unit Deepseek;

{-------------------------------------------------------------------------------

      Github repository :  https://github.com/MaxiDonkey/DelphiDeepseek
      Visit the Github repository for the documentation and use examples

 ------------------------------------------------------------------------------}

interface

uses
  System.SysUtils, System.Classes, System.Net.URLClient, Deepseek.API, Deepseek.API.Params,
  Deepseek.Models, Deepseek.Chat, Deepseek.FIM, Deepseek.User, Deepseek.Functions.Core,
  Deepseek.HttpClient.Intf, Deepseek.HttpClient, Deepseek.Monitoring, Deepseek.API.Parallel;

const
  VERSION = 'Deepseekv1.0.4';

type
  /// <summary>
  /// The <c>IDeepseek</c> interface provides access to the various features and routes of the Deepseek AI API.
  /// It serves as a comprehensive framework for automating natural language processing, vision tasks, and
  /// data retrieval workflows.
  /// </summary>
  /// <remarks>
  /// This interface should be implemented by any class that wants to provide a structured way of accessing
  /// the Deepseek AI services. It includes methods and properties for authenticating with an API key,
  /// configuring the base URL, and accessing different API routes.
  /// </remarks>
  IDeepseek = interface
    ['{59A59450-F0CB-4FA3-8EF6-E8D0EB8A1118}']
    function GetAPI: TDeepseekAPI;
    procedure SetKey(const Value: string);
    function GetKey: string;
    function GetBaseUrl: string;
    procedure SetBaseUrl(const Value: string);
    function GetClientHttp: IHttpClientAPI;
    function GetVersion: string;

    function GetChatRoute: TChatRoute;
    function GetFIMRoute: TFIMRoute;
    function GetModelsRoute: TModelsRoute;
    function GetUserRoute: TUserRoute;

    /// <summary>
    /// Gets the current version of the Deepseek library.
    /// </summary>
    /// <remarks>
    /// The <c>Version</c> property provides the semantic version number of the library as a string.
    /// This can be used for compatibility checks or displaying version information in your application.
    /// </remarks>
    /// <returns>
    /// A string representing the library version.
    /// </returns>
    property Version: string read GetVersion;

    /// <summary>
    /// This class offers functionality for generating contextually appropriate responses within
    /// conversational frameworks.
    /// </summary>
    property Chat: TChatRoute read GetChatRoute;

    /// <summary>
    /// This class implements the FIM (Fill In the Middle) completion functionality, allowing users
    /// to generate content or code by providing a prefix and an optional suffix. FIM completion is
    /// particularly useful for cases where contextual insertion is required between two existing
    ///text segments.
    /// </summary>
    /// <remarks>
    /// Typical usage:
    /// <para>
    /// - Text completion: Generate missing content in a partially written document.
    /// </para>
    /// <para>
    /// - Code completion: Add code fragments in a given context (e.g., between existing code blocks).
    /// </para>
    /// </remarks>
    property FIM: TFIMRoute read GetFIMRoute;

    /// <summary>
    /// Provides methods for interacting with the Deepseek API to retrieve models.
    /// It offers both synchronous and asynchronous operations
    /// for listing and retrieving individual models.
    /// </summary>
    property Models: TModelsRoute read GetModelsRoute;

    /// <summary>
    /// This provides methods for user management including current balance.
    /// </summary>
    property User: TUserRoute read GetUserRoute;

    /// <summary>
    /// the main API object used for making requests.
    /// </summary>
    /// <returns>
    /// An instance of TDeepseekAPI for making API calls.
    /// </returns>
    property API: TDeepseekAPI read GetAPI;

    /// <summary>
    /// Sets or retrieves the API token for authentication.
    /// </summary>
    property Key: string read GetKey write SetKey;

    /// <summary>
    /// Sets or retrieves the base URL for API requests.
    /// Default is https://api.deepseek.com
    /// </summary>
    property BaseURL: string read GetBaseUrl write SetBaseUrl;

    /// <summary>
    /// The HTTP client interface used for making API calls.
    /// </summary>
    property ClientHttp: IHttpClientAPI read GetClientHttp;
  end;

  /// <summary>
  /// The <c>TDeepseekFactory</c> class is responsible for creating instances of
  /// the <see cref="IDeepseek"/> interface. It provides a factory method to instantiate
  /// the interface with a provided API token and optional header configuration.
  /// </summary>
  /// <remarks>
  /// This class provides a convenient way to initialize the <see cref="IDeepseek"/> interface
  /// by encapsulating the necessary configuration details, such as the API token and header options.
  /// By using the factory method, users can quickly create instances of <see cref="IDeepseek"/> without
  /// manually setting up the implementation details.
  /// </remarks>
  TDeepseekFactory = class
    /// <summary>
    /// Creates an instance of the <see cref="IDeepseek"/> interface with the specified API token
    /// and optional header configuration.
    /// </summary>
    /// <param name="AToken">
    /// The API token as a string, required for authenticating with Deepseek API services.
    /// </param>
    /// <returns>
    /// An instance of <see cref="IDeepseek"/> initialized with the provided API token and header option.
    /// </returns>
    /// <remarks>
    /// Code example
    /// <code>
    /// var Deepseek := TDeepseekFactory.CreateInstance(BaererKey);
    /// </code>
    /// WARNING : Please take care to adjust the SCOPE of the <c>DeepseekCloud</c> interface in you application.
    /// </remarks>
    class function CreateInstance(const AToken: string): IDeepseek;

    /// <summary>
    /// Creates an instance of the <c>IDeepseek</c> interface with the specified API token.
    /// <para>
    /// The base url for the beta instance : https://api.deepseek.com/beta
    /// </para>
    /// </summary>
    /// <param name="AToken">
    /// The API token as a string, required for authenticating with Deepseek API services.
    /// </param>
    /// <returns>
    /// An instance of <see cref="IDeepseek"/> initialized with the provided API token and header option.
    /// </returns>
    /// <remarks>
    /// Code example
    /// <code>
    /// var DeepseekBeta := TDeepseekFactory.CreateBetaInstance(BaererKey);
    /// </code>
    /// WARNING : Please take care to adjust the SCOPE of the <c>DeepseekCloud</c> interface in you application.
    /// </remarks>
    class function CreateBetaInstance(const AToken: string): IDeepseek;

    /// <summary>
    /// Creates an <see cref="IDeepseek"/> instance configured to run models locally
    /// through an LM Studio server.
    /// </summary>
    /// <param name="URLBase">
    /// Optional base URL of the LM Studio server (for example, "http://127.0.0.1:1234").
    /// If this parameter is empty, the default LM Studio server URL is used.
    /// Do not append the "/v1" path segment; it is added automatically by the library.
    /// </param>
    /// <returns>
    /// An <see cref="IDeepseek"/> instance whose requests are routed to the configured
    /// LM Studio server instead of the remote Deepseek API.
    /// </returns>
    /// <remarks>
    /// Use this factory method when you want to execute models locally via LM Studio
    /// rather than calling the hosted Deepseek endpoints.
    /// Before using the returned instance, make sure that the LM Studio server is
    /// running and that its status is shown as <c>Running</c> in the LM Studio UI.
    /// </remarks>
    class function CreateLMSInstance(const URLBase: string = ''): IDeepseek;
  end;

  /// <summary>
  /// The TDeepseek class provides access to the various features and routes of the Deepseek AI API.
  /// It serves as a comprehensive framework for automating natural language processing, vision tasks, and data retrieval workflows.
  /// </summary>
  /// <remarks>
  /// This class should be implemented by any class that wants to provide a structured way of accessing
  /// the Deepseek AI services. It includes methods and properties for authenticating with an API key,
  /// configuring the base URL, and accessing different API routes.
  /// <seealso cref="TDeepseek"/>
  /// </remarks>
  TDeepseek = class(TInterfacedObject, IDeepseek)
  strict private

  private
    FAPI: TDeepseekAPI;
    FChatRoute: TChatRoute;
    FModelsRoute: TModelsRoute;
    FFIMRoute: TFIMRoute;
    FUserRoute: TUserRoute;

    function GetAPI: TDeepseekAPI;
    function GetKey: string;
    procedure SetKey(const Value: string);
    function GetBaseUrl: string;
    procedure SetBaseUrl(const Value: string);
    function GetClientHttp: IHttpClientAPI;
    function GetVersion: string;

    function GetChatRoute: TChatRoute;
    function GetFIMRoute: TFIMRoute;
    function GetModelsRoute: TModelsRoute;
    function GetUserRoute: TUserRoute;

  public
    /// <summary>
    /// This class offers functionality for generating contextually appropriate responses within
    /// conversational frameworks.
    /// </summary>
    property Chat: TChatRoute read GetChatRoute;

    /// <summary>
    /// Provides methods for interacting with the Deepseek API to retrieve models.
    /// It offers both synchronous and asynchronous operations
    /// for listing and retrieving individual models.
    /// </summary>
    /// <summary>
    /// This class implements the FIM (Fill In the Middle) completion functionality, allowing users
    /// to generate content or code by providing a prefix and an optional suffix. FIM completion is
    /// particularly useful for cases where contextual insertion is required between two existing
    ///text segments.
    /// </summary>
    /// <remarks>
    /// Typical usage:
    /// <para>
    /// - Text completion: Generate missing content in a partially written document.
    /// </para>
    /// <para>
    /// - Code completion: Add code fragments in a given context (e.g., between existing code blocks).
    /// </para>
    /// </remarks>
    property FIM: TFIMRoute read GetFIMRoute;

    /// <summary>
    /// Provides methods for interacting with the Deepseek API to retrieve models.
    /// It offers both synchronous and asynchronous operations
    /// for listing and retrieving individual models.
    /// </summary>
    property Models: TModelsRoute read GetModelsRoute;

    /// <summary>
    /// This provides methods for user management including current balance.
    /// </summary>
    property User: TUserRoute read GetUserRoute;

    /// <summary>
    /// the main API object used for making requests.
    /// </summary>
    /// <returns>
    /// An instance of TDeepseekAPI for making API calls.
    /// </returns>
    property API: TDeepseekAPI read GetAPI;

    /// <summary>
    /// Sets or retrieves the API token for authentication.
    /// </summary>
    /// <param name="Value">
    /// The API token as a string.
    /// </param>
    /// <returns>
    /// The current API token.
    /// </returns>
    property Token: string read GetKey write SetKey;

    /// <summary>
    /// Sets or retrieves the base URL for API requests.
    /// Default is https://api.deepseek.com
    /// </summary>
    /// <param name="Value">
    /// The base URL as a string.
    /// </param>
    /// <returns>
    /// The current base URL.
    /// </returns>
    property BaseURL: string read GetBaseUrl write SetBaseUrl;

  public
    /// <summary>
    /// Initializes a new instance of the <see cref="TDeepseek"/> class with optional header configuration.
    /// </summary>
    /// <param name="Option">
    /// An optional parameter of type <see cref="THeaderOption"/> to configure the request headers.
    /// The default value is <c>THeaderOption.none</c>.
    /// </param>
    /// <remarks>
    /// This constructor is typically used when no API token is provided initially.
    /// The token can be set later via the <see cref="Token"/> property.
    /// </remarks>
    constructor Create(const LocalLMS: Boolean = False); overload;

    /// <summary>
    /// Initializes a new instance of the <see cref="TDeepseek"/> class with the provided API token and optional header configuration.
    /// </summary>
    /// <param name="AToken">
    /// The API token as a string, required for authenticating with the Deepseek AI API.
    /// </param>
    /// <param name="Option">
    /// An optional parameter of type <see cref="THeaderOption"/> to configure the request headers.
    /// The default value is <c>THeaderOption.none</c>.
    /// </param>
    /// <remarks>
    /// This constructor allows the user to specify an API token at the time of initialization.
    /// </remarks>
    constructor Create(const AToken: string; const LocalLMS: Boolean = False); overload;

    /// <summary>
    /// Releases all resources used by the current instance of the <see cref="TDeepseek"/> class.
    /// </summary>
    /// <remarks>
    /// This method is called to clean up any resources before the object is destroyed.
    /// It overrides the base <see cref="TInterfacedObject.Destroy"/> method.
    /// </remarks>
    destructor Destroy; override;
  end;

  {$REGION 'Deepseek.Chat'}

  /// <summary>
  /// Messages comprising the conversation so far.
  /// </summary>
  TContentParams = Deepseek.Chat.TContentParams;

  /// <summary>
  /// The <c>TChatParams</c> class represents the set of parameters used to configure a chat interaction with an AI model.
  /// </summary>
  /// <remarks>
  /// This class allows you to define various settings that control how the model behaves, including which model to use, how many tokens to generate,
  /// what kind of messages to send, and how the model should handle its output. By using this class, you can fine-tune the AI's behavior and response format
  /// based on your application's specific needs.
  /// <para>
  /// It inherits from <c>TJSONParam</c>, which provides methods for handling and serializing the parameters as JSON, allowing seamless integration
  /// with JSON-based APIs.
  /// </para>
  /// <code>
  /// var
  ///   Params: TChatParams;
  /// begin
  ///   Params := TChatParams.Create
  ///     .Model('my_model')
  ///     .MaxTokens(100)
  ///     .Messages([TChatMessagePayload.User('Hello!')])
  ///     .ResponseFormat('json_object')
  ///     .Temperature(0.7)
  ///     .TopP(1)
  ///     .SafePrompt(True);
  /// end;
  /// </code>
  /// This example shows how to instantiate and configure a <c>TChatParams</c> object for interacting with an AI model.
  /// </remarks>
  TChatParams = Deepseek.Chat.TChatParams;

  /// <summary>
  /// Represents the buffer for accumulating streamed chat response data.
  /// </summary>
  /// <remarks>
  /// <para>The <c>TPromiseBuffer</c> record stores information collected during a streaming chat operation.</para>
  /// <para><see cref="Content"/> holds the incremental text output from the assistant as it arrives.</para>
  /// <para><see cref="Reasoning"/> holds any reasoning content delivered before the final output.</para>
  /// <para>This buffer is returned to the caller once the stream completes.</para>
  /// </remarks>
  TPromiseBuffer = Deepseek.Chat.TPromiseBuffer;

  /// <summary>
  /// Represents the specifics of a called function, including its name and calculated arguments.
  /// </summary>
  TFunction = Deepseek.Chat.TFunction;

  /// <summary>
  /// Represents a called function, containing its specifics such as name and arguments.
  /// </summary>
  TToolCalls = Deepseek.Chat.TToolCalls;

  /// <summary>
  /// Represents a chat message exchanged between participants (user, assistant, or system) in a conversation.
  /// </summary>
  /// <remarks>
  /// The <c>TChoiceMessage</c> class encapsulates the essential information of a message within a chat application, including:
  /// <para>
  /// - The role of the sender (user, assistant, or system).
  /// </para>
  /// <para>
  /// - The content of the message itself.
  /// </para>
  /// <para>
  /// - Optionally, a list of tool calls that may be required to complete the message response.
  /// </para>
  /// This class is fundamental for managing the flow of a conversation, allowing the system to track who said what and what actions need to be taken.
  /// </remarks>
  TChoiceMessage = Deepseek.Chat.TChoiceMessage;

  /// <summary>
  /// Represents the top log probabilities of tokens in a model's output.
  /// </summary>
  /// <remarks>
  /// The <c>TTopLogprobs</c> class is used to encapsulate detailed information
  /// about the probabilities of the most likely tokens at a specific position
  /// during the generation of a model's output.
  /// <para>
  /// This class is useful for analyzing and debugging the behavior of language
  /// models by providing a deeper insight into the decision-making process at
  /// the token level.
  /// </para>
  /// <para>
  /// It includes the token, its log probability, and its byte representation
  /// in UTF-8 format, making it an essential tool for advanced token-level
  /// evaluations.
  /// </para>
  /// </remarks>
  TTopLogprobs = Deepseek.Chat.TTopLogprobs;

  /// <summary>
  /// Represents detailed log probability information for a specific token.
  /// </summary>
  /// <remarks>
  /// The <c>TLogprobContent</c> class provides a comprehensive structure for storing
  /// and analyzing the log probabilities of tokens generated by a model.
  /// It includes:
  /// <para>- The token itself.</para>
  /// <para>- The log probability of the token.</para>
  /// <para>- The UTF-8 byte representation of the token, when applicable.</para>
  /// <para>- A list of the most likely tokens and their log probabilities at this position,
  /// represented by <c>TTopLogprobs</c>.</para>
  /// <para>
  /// This class is particularly useful in tasks requiring token-level analysis,
  /// such as understanding model decisions, debugging outputs, or assessing
  /// the confidence of specific token choices.
  /// </para>
  /// </remarks>
  TLogprobContent = Deepseek.Chat.TLogprobContent;

  /// <summary>
  /// Represents the aggregated log probability information for a choice's output.
  /// </summary>
  /// <remarks>
  /// The <c>TLogprobs</c> class provides a structured way to encapsulate
  /// log probability data for tokens generated during a model's output.
  /// It consists of a collection of <c>TLogprobContent</c> instances,
  /// each representing detailed information for a single token.
  /// <para>
  /// This class is essential for advanced token-level analysis, allowing developers
  /// to assess the confidence of a model's predictions and understand the
  /// distribution of token probabilities across an entire response.
  /// </para>
  /// </remarks>
  TLogprobs = Deepseek.Chat.TLogprobs;

  /// <summary>
  /// Represents incremental updates to a chat message during streaming responses.
  /// </summary>
  /// <remarks>
  /// The <c>TDelta</c> class provides a structure to encapsulate partial or
  /// incremental updates to a chat message during streaming interactions
  /// with an AI model. It includes:
  /// <para>- The content of the partial message.</para>
  /// <para>- The role of the author of the message (e.g., user, assistant, or system).</para>
  /// <para>
  /// - This class is particularly useful for real-time applications where responses
  /// are streamed as they are generated, allowing for dynamic updates to the
  /// conversation interface.
  /// </para>
  /// <para>
  /// - Does not allow handling function calls during SSE processing.
  /// </para>
  /// </remarks>
  TDelta = Deepseek.Chat.TDelta;

  /// <summary>
  /// Represents a single completion option generated by the AI model during a chat interaction.
  /// </summary>
  /// <remarks>
  /// The <c>TChatChoice</c> class stores the results of the AI model's response to a user prompt. Each instance of this class represents one of potentially
  /// many choices that the model could return. This includes:
  /// <para>
  /// - The finish reason.
  /// </para>
  /// <para>
  /// - An index identifying the choice.
  /// </para>
  /// <para>
  /// - A message generated by the model.
  /// </para>
  /// <para>
  /// - Optional deltas for streamed responses.
  /// </para>
  /// <para>
  /// - The reason the model stopped generating tokens.
  /// </para>
  /// This class is useful when multiple potential responses are generated and evaluated, or when streaming responses incrementally.
  /// </remarks>
  TChatChoice = Deepseek.Chat.TChatChoice;

  /// <summary>
  /// Represents the token usage statistics for a chat interaction, including the number of tokens
  /// used in the prompt, the completion, and the total number of tokens consumed.
  /// </summary>
  /// <remarks>
  /// The <c>TChatUsage</c> class provides insight into the number of tokens used during a chat interaction.
  /// This information is critical for understanding the cost of a request when using token-based billing systems
  /// or for monitoring the model's behavior in terms of input (prompt) and output (completion) size.
  /// </remarks>
  TUsage = Deepseek.Chat.TUsage;

  /// <summary>
  /// Represents a chat completion response generated by an AI model, containing the necessary metadata,
  /// the generated choices, and usage statistics.
  /// </summary>
  /// <remarks>
  /// The <c>TChat</c> class encapsulates the results of a chat request made to an AI model.
  /// It contains details such as a unique identifier, the model used, when the completion was created,
  /// the choices generated by the model, and token usage statistics.
  /// This class is crucial for managing the results of AI-driven conversations and understanding the
  /// underlying usage and response characteristics of the AI.
  /// </remarks>
  TChat = Deepseek.Chat.TChat;

  /// <summary>
  /// Manages asynchronous chat callBacks for a chat request using <c>TChat</c> as the response type.
  /// </summary>
  /// <remarks>
  /// The <c>TAsynChat</c> type extends the <c>TAsynParams&lt;TChat&gt;</c> record to handle the lifecycle of an asynchronous chat operation.
  /// It provides event handlers that trigger at various stages, such as when the operation starts, completes successfully, or encounters an error.
  /// This structure facilitates non-blocking chat operations and is specifically tailored for scenarios where multiple choices from a chat model are required.
  /// </remarks>
  TAsynChat = Deepseek.Chat.TAsynChat;

  /// <summary>
  /// Represents a promise-based callback for an asynchronous chat operation.
  /// </summary>
  /// <remarks>
  /// The <c>TPromiseChat</c> alias extends <see cref="TPromiseCallBack&lt;TChat&gt;"/>
  /// to provide a promise-style API for chat completions, yielding a <see cref="TChat"/>
  /// instance when the operation succeeds or raising an exception on failure.
  /// </remarks>
  TPromiseChat = Deepseek.Chat.TPromiseChat;

  /// <summary>
  /// Manages asynchronous streaming chat callBacks for a chat request using <c>TChat</c> as the response type.
  /// </summary>
  /// <remarks>
  /// The <c>TAsynChatStream</c> type extends the <c>TAsynStreamParams&lt;TChat&gt;</c> record to support the lifecycle of an asynchronous streaming chat operation.
  /// It provides callbacks for different stages, including when the operation starts, progresses with new data chunks, completes successfully, or encounters an error.
  /// This structure is ideal for handling scenarios where the chat response is streamed incrementally, providing real-time updates to the user interface.
  /// </remarks>
  TAsynChatStream = Deepseek.Chat.TAsynChatStream;

  /// <summary>
  /// Represents a promise-based callback for streaming chat operations.
  /// </summary>
  /// <remarks>
  /// The <c>TPromiseChatStream</c> alias extends <see cref="TPromiseStreamCallBack&lt;TChat&gt;"/>
  /// to provide a promise-style API for streaming chat completions, delivering incremental <see cref="TChat"/>
  /// updates until the stream finishes or an error is encountered.
  /// </remarks>
  TPromiseChatStream = Deepseek.Chat.TPromiseChatStream;

  /// <summary>
  /// Represents a callback procedure used during the reception of responses from a chat request in streaming mode.
  /// </summary>
  /// <param name="Chat">
  /// The <c>TChat</c> object containing the current information about the response generated by the model.
  /// If this value is <c>nil</c>, it indicates that the data stream is complete.
  /// </param>
  /// <param name="IsDone">
  /// A boolean flag indicating whether the streaming process is complete.
  /// If <c>True</c>, it means the model has finished sending all response data.
  /// </param>
  /// <param name="Cancel">
  /// A boolean flag that can be set to <c>True</c> within the callback to cancel the streaming process.
  /// If set to <c>True</c>, the streaming will be terminated immediately.
  /// </param>
  /// <remarks>
  /// This callback is invoked multiple times during the reception of the response data from the model.
  /// It allows for real-time processing of received messages and interaction with the user interface or other systems
  /// based on the state of the data stream.
  /// When the <c>IsDone</c> parameter is <c>True</c>, it indicates that the model has finished responding,
  /// and the <c>Chat</c> parameter will be <c>nil</c>.
  /// </remarks>
  TChatEvent = Deepseek.Chat.TChatEvent;

  {$ENDREGION}

  {$REGION 'Deepseek.FIM'}

  /// <summary>
  /// Represents a parameter configuration class for the "FIM" model.
  /// </summary>
  /// <remarks>
  /// The <c>TFIMParams</c> class provides methods to set various parameters used for configuring
  /// and customizing requests to the "FIM" (Fill-In-the-Middle) AI model. This includes options
  /// such as the model identifier, prompt text, token limits, penalties, and other advanced settings.
  /// The methods in this class are chainable, allowing for streamlined parameter configuration.
  /// </remarks>
  TFIMParams = Deepseek.FIM.TFIMParams;

  /// <summary>
  /// Represents the top log probabilities for tokens generated by the model.
  /// </summary>
  /// <remarks>
  /// The <c>TFIMToplogprobs</c> class provides detailed information about the
  /// probabilities of tokens chosen by the model, including their text offsets
  /// and associated probabilities.
  /// </remarks>
  TFIMToplogprobs = Deepseek.FIM.TFIMToplogprobs;

  /// <summary>
  /// Represents the log probabilities of tokens generated by the model.
  /// </summary>
  /// <remarks>
  /// The <c>TFIMLogprobs</c> class stores detailed information about the probabilities of tokens
  /// generated during a completion request. It includes data such as the tokens themselves,
  /// their respective log probabilities, and the character offsets of each token in the response text.
  /// Additionally, it can provide detailed insights into the top alternative tokens and their probabilities
  /// at each generation step.
  /// </remarks>
  TFIMLogprobs = Deepseek.FIM.TFIMLogprobs;

  /// <summary>
  /// Represents a choice generated by the AI model in response to a completion request.
  /// </summary>
  /// <remarks>
  /// The <c>TFIMChoice</c> class contains details about a specific choice produced by the AI model,
  /// including the generated text, associated log probabilities, the index of the choice,
  /// and the reason why the model stopped generating further tokens.
  /// </remarks>
  TFIMChoice = Deepseek.FIM.TFIMChoice;

  /// <summary>
  /// Represents the main class for managing text completion responses.
  /// </summary>
  /// <remarks>
  /// The <c>TFIM</c> class encapsulates the details of a completion operation performed by an AI model.
  /// It includes properties such as the generated text choices, metadata about the completion, and usage statistics.
  /// This class is designed to work with the Deepseek API for handling text completions.
  /// </remarks>
  TFIM = Deepseek.FIM.TFIM;

  /// <summary>
  /// Manages asynchronous chat callBacks for a chat request using <c>TFIM</c> as the response type.
  /// </summary>
  /// <remarks>
  /// The <c>TAsynFIM</c> type extends the <c>TAsynParams&lt;TFIM&gt;</c> record to handle the lifecycle of an asynchronous chat operation.
  /// It provides event handlers that trigger at various stages, such as when the operation starts, completes successfully, or encounters an error.
  /// This structure facilitates non-blocking chat operations and is specifically tailored for scenarios where multiple choices from a chat model are required.
  /// </remarks>
  TAsynFIM = Deepseek.FIM.TAsynFIM;

  /// <summary>
  /// Manages asynchronous streaming chat callBacks for a chat request using <c>TFIM</c> as the response type.
  /// </summary>
  /// <remarks>
  /// The <c>TAsynFIMStream</c> type extends the <c>TAsynStreamParams&lt;TFIM&gt;</c> record to support the lifecycle of an asynchronous streaming chat operation.
  /// It provides callbacks for different stages, including when the operation starts, progresses with new data chunks, completes successfully, or encounters an error.
  /// This structure is ideal for handling scenarios where the chat response is streamed incrementally, providing real-time updates to the user interface.
  /// </remarks>
  TAsynFIMStream = Deepseek.FIM.TAsynFIMStream;

  /// <summary>
  /// Represents a callback procedure used during the reception of responses from a chat request in streaming mode.
  /// </summary>
  /// <param name="FIM">
  /// The <c>TFIM</c> object containing the current information about the response generated by the model.
  /// If this value is <c>nil</c>, it indicates that the data stream is complete.
  /// </param>
  /// <param name="IsDone">
  /// A boolean flag indicating whether the streaming process is complete.
  /// If <c>True</c>, it means the model has finished sending all response data.
  /// </param>
  /// <param name="Cancel">
  /// A boolean flag that can be set to <c>True</c> within the callback to cancel the streaming process.
  /// If set to <c>True</c>, the streaming will be terminated immediately.
  /// </param>
  /// <remarks>
  /// This callback is invoked multiple times during the reception of the response data from the model.
  /// It allows for real-time processing of received messages and interaction with the user interface or other systems
  /// based on the state of the data stream.
  /// When the <c>IsDone</c> parameter is <c>True</c>, it indicates that the model has finished responding,
  /// and the <c>TFIM</c> parameter will be <c>nil</c>.
  /// </remarks>
  TFIMEvent = Deepseek.FIM.TFIMEvent;

  {$ENDREGION}

  {$REGION 'Deepseek.Models'}

  /// <summary>
  /// The <c>TModel</c> class represents a model entity retrieved from the Deepseek API.
  /// It encapsulates basic information about the model, including its unique identifier,
  /// object type, and ownership details.
  /// </summary>
  /// <remarks>
  /// This class is designed to be used as part of the Deepseek framework for API integrations.
  /// Instances of <c>TModel</c> are typically created as a result of API calls
  /// and provide detailed information about individual models available within the system.
  /// Key properties include <c>Id</c>, which identifies the model uniquely,
  /// <c>Object</c>, which specifies the type of the object, and <c>OwnedBy</c>,
  /// indicating the organ
  TModel = Deepseek.Models.TModel;

  /// <summary>
  /// The <c>TModels</c> class represents a collection of model entities retrieved from the Deepseek API.
  /// It provides information about the collection as a whole and an array of individual models.
  /// </summary>
  /// <remarks>
  /// This class is used to handle the response from API endpoints that return a list of models.
  /// The <c>Object</c> property indicates the type of the object, typically set to "list",
  /// while the <c>Data</c> property contains an array of <c>TModel</c> instances representing each model in the collection.
  /// Instances of this class are created as a result of API calls to list available models.
  /// </remarks>
  TModels = Deepseek.Models.TModels;

  /// <summary>
  /// The <c>TModelsRoute</c> class provides methods for interacting with the Deepseek API
  /// to retrieve and manage models. It offers both synchronous and asynchronous operations
  /// for listing and retrieving individual models.
  /// </summary>
  /// <remarks>
  /// This class serves as a high-level interface for accessing model-related API endpoints.
  /// It extends the <c>TDeepseekAPIRoute</c> class, inheriting base functionalities
  /// while adding methods specific to model operations.
  /// <para>
  /// Key functionalities include:
  /// <list type="bullet">
  /// <item><description>Listing all available models using <c>List</c> and <c>AsynList</c> methods.</description></item>
  /// <item><description>Retrieving details of a specific model by its ID using <c>Retrieve</c> and <c>AsynRetrieve</c> methods.</description></item>
  /// </list>
  /// </para>
  /// <para>
  /// Asynchronous methods (<c>AsynList</c> and <c>AsynRetrieve</c>) allow the application
  /// to handle API responses in a non-blocking manner, suitable for UI-intensive scenarios.
  /// Synchronous methods (<c>List</c> and <c>Retrieve</c>) block execution until the API response is received.
  /// </para>
  /// </remarks>
  TAsynModel = Deepseek.Models.TAsynModel;

  /// <summary>
  /// The <c>TAsynModels</c> class is a type alias used to handle asynchronous callbacks for batch processing.
  /// It provides support for executing batch operations asynchronously and processing the results upon completion.
  /// </summary>
  /// <remarks>
  /// This class is part of the asynchronous framework that allows non-blocking batch operations.
  /// It uses a callback mechanism to return the result of a batch process once it is completed.
  /// </remarks>
  TAsynModels = Deepseek.Models.TAsynModels;

  {$ENDREGION}

  {$REGION 'Deepseek.User'}

  /// <summary>
  /// Represents detailed information about a user's balance in a specific currency.
  /// </summary>
  /// <remarks>
  /// This class encapsulates information about the user's balance, including the total available balance,
  /// granted balance, and topped-up balance, all categorized by currency.
  /// </remarks>
  TBalanceInfo = Deepseek.User.TBalanceInfo;

  /// <summary>
  /// Represents the user's balance and its availability for API usage.
  /// </summary>
  /// <remarks>
  /// This class provides information about whether the user's balance is sufficient for API calls
  /// and includes detailed balance information across different currencies.
  /// </remarks>
  TBalance = Deepseek.User.TBalance;

  /// <summary>
  /// Manages asynchronous chat callBacks for a chat request using <c>TBalance</c> as the response type.
  /// </summary>
  /// <remarks>
  /// The <c>TAsynBalance</c> type extends the <c>TAsynParams&lt;TBalance&gt;</c> record to handle the lifecycle of an asynchronous chat operation.
  /// It provides event handlers that trigger at various stages, such as when the operation starts, completes successfully, or encounters an error.
  /// This structure facilitates non-blocking chat operations and is specifically tailored for scenarios where multiple choices from a chat model are required.
  /// </remarks>
  TAsynBalance = Deepseek.User.TAsynBalance;

  {$ENDREGION}

  {$REGION 'Deepseek.Functions.Core'}

  /// <summary>
  /// Interface defining the core structure and functionality of a function in the system.
  /// </summary>
  /// <remarks>
  /// This interface outlines the basic properties and methods that any function implementation must include.
  /// </remarks>
  IFunctionCore = Deepseek.Functions.Core.IFunctionCore;

  /// <summary>
  /// Abstract base class for implementing core function behavior.
  /// </summary>
  /// <remarks>
  /// This class provides basic implementations for some methods and defines the structure that derived classes must follow.
  /// </remarks>
  TFunctionCore = Deepseek.Functions.Core.TFunctionCore;

  {$ENDREGION}

  {$REGION 'Deepseek.API.Parallel'}

  /// <summary>
  /// Represents an item in a bundle of chat prompts and responses.
  /// </summary>
  /// <remarks>
  /// This class stores information about a single chat request, including its index,
  /// associated prompt, generated response, and related chat object.
  /// It is used within a <c>TBundleList</c> to manage multiple asynchronous chat requests.
  /// </remarks>
  TBundleItem = Deepseek.API.Parallel.TBundleItem;

  /// <summary>
  /// Manages a collection of <c>TBundleItem</c> objects.
  /// </summary>
  /// <remarks>
  /// This class provides methods to add, retrieve, and count items in a bundle.
  /// It is designed to store multiple chat request items processed in parallel.
  /// The internal storage uses a <c>TObjectList&lt;TBundleItem&gt;</c> with automatic memory management.
  /// </remarks>
  TBundleList = Deepseek.API.Parallel.TBundleList;

  /// <summary>
  /// Represents an asynchronous callback buffer for handling chat responses.
  /// </summary>
  /// <remarks>
  /// This class is a specialized type used to manage asynchronous operations
  /// related to chat request processing. It inherits from <c>TAsynCallBack&lt;TBundleList&gt;</c>,
  /// enabling structured handling of callback events.
  /// </remarks>
  TAsynBundleList = Deepseek.API.Parallel.TAsynBundleList;

  /// <summary>
  /// Represents a promise-based callback for handling a bundle of chat responses.
  /// </summary>
  /// <remarks>
  /// The <c>TPromiseBundleList</c> alias extends <see cref="TPromiseCallBack&lt;TBundleList&gt;"/>
  /// to provide a promise-style API for parallel chat prompt execution, resolving with a
  /// <see cref="TBundleList"/> when all responses are complete or rejecting on error.
  /// </remarks>
  TPromiseBundleList = Deepseek.API.Parallel.TPromiseBundleList;

  /// <summary>
  /// Provides helper methods for managing asynchronous tasks.
  /// </summary>
  /// <remarks>
  /// This class contains utility methods for handling task execution flow,
  /// including a method to execute a follow-up action once a task completes.
  /// <para>
  /// - In order to replace TTask.WaitForAll due to a memory leak in TLightweightEvent/TCompleteEventsWrapper.
  /// See report RSP-12462 and RSP-25999.
  /// </para>
  /// </remarks>
  TTaskHelper = Deepseek.API.Parallel.TTaskHelper;

  /// <summary>
  /// Represents the parameters used for configuring a chat request bundle.
  /// </summary>
  /// <remarks>
  /// This class extends <c>TParameters</c> and provides specific methods for setting chat-related
  /// parameters, such as prompts, model selection, and reasoning effort.
  /// It is used to structure and pass multiple requests efficiently in parallel processing.
  /// </remarks>
  TBundleParams = Deepseek.API.Parallel.TBundleParams;

  {$ENDREGION}

/// <summary>
/// Creates a <see cref="TContentParams"/> instance representing a user-provided message.
/// </summary>
/// <param name="Value">
/// The content of the message provided by the user.
/// </param>
/// <param name="Name">
/// An optional parameter specifying the name of the user. Default is an empty string.
/// </param>
/// <returns>
/// An instance of <see cref="TContentParams"/> configured as a user message.
/// </returns>
function FromUser(const Value: string; const Name: string = ''): TContentParams;

/// <summary>
/// Creates a <see cref="TContentParams"/> instance representing an assistant-generated message.
/// </summary>
/// <param name="Value">
/// The content of the message generated by the assistant.
/// </param>
/// <param name="Prefix">
/// A boolean value indicating whether the message should include a prefix. Default is <c>false</c>.
/// </param>
/// <returns>
/// An instance of <see cref="TContentParams"/> configured as an assistant message.
/// </returns>
function FromAssistant(const Value: string; const Prefix: Boolean = False): TContentParams; overload;

/// <summary>
/// Creates a <see cref="TContentParams"/> instance representing an assistant-generated message, with an optional name.
/// </summary>
/// <param name="Value">
/// The content of the message generated by the assistant.
/// </param>
/// <param name="Name">
/// An optional parameter specifying the name of the assistant.
/// </param>
/// <param name="Prefix">
/// A boolean value indicating whether the message should include a prefix. Default is <c>false</c>.
/// </param>
/// <returns>
/// An instance of <see cref="TContentParams"/> configured as an assistant message with a name.
/// </returns>
function FromAssistant(const Value, Name: string; const Prefix: Boolean = False): TContentParams; overload;

/// <summary>
/// Creates a <see cref="TContentParams"/> instance representing a system-generated message.
/// </summary>
/// <param name="Value">
/// The content of the message generated by the system.
/// </param>
/// <param name="Name">
/// An optional parameter specifying the name of the system. Default is an empty string.
/// </param>
/// <returns>
/// An instance of <see cref="TContentParams"/> configured as a system message.
/// </returns>
function FromSystem(const Value: string; const Name: string = ''): TContentParams;

function HttpMonitoring: IRequestMonitor;

implementation

function FromUser(const Value: string; const Name: string): TContentParams;
begin
  Result := TContentParams.User(Value, Name);
end;

function FromAssistant(const Value: string; const Prefix: Boolean): TContentParams;
begin
  Result := TContentParams.Assistant(Value, Prefix);
end;

function FromAssistant(const Value, Name: string; const Prefix: Boolean): TContentParams;
begin
  Result := TContentParams.Assistant(Value, Name, Prefix);
end;

function FromSystem(const Value: string; const Name: string): TContentParams;
begin
  Result := TContentParams.System(Value, Name);
end;

function HttpMonitoring: IRequestMonitor;
begin
  Result := Monitoring;
end;

{ TDeepseek }

constructor TDeepseek.Create(const LocalLMS: Boolean);
begin
  inherited Create;
  FAPI := TDeepseekAPI.Create(LocalLMS);
end;

constructor TDeepseek.Create(const AToken: string; const LocalLMS: Boolean);
begin
  Create(LocalLMS);
  Token := AToken;
end;

destructor TDeepseek.Destroy;
begin
  FAPI.Free;
  FChatRoute.Free;
  FFIMRoute.Free;
  FModelsRoute.Free;
  FUserRoute.Free;
  inherited;
end;

function TDeepseek.GetAPI: TDeepseekAPI;
begin
  Result := FAPI;
end;

function TDeepseek.GetBaseUrl: string;
begin
  Result := FAPI.BaseURL;
end;

function TDeepseek.GetModelsRoute: TModelsRoute;
begin
  if not Assigned(FModelsRoute) then
    FModelsRoute := TModelsRoute.CreateRoute(API);
  Result := FModelsRoute;
end;

function TDeepseek.GetChatRoute: TChatRoute;
begin
  if not Assigned(FChatRoute) then
    FChatRoute := TChatRoute.CreateRoute(API);
  Result := FChatRoute;
end;

function TDeepseek.GetClientHttp: IHttpClientAPI;
begin
  Result := API.ClientHttp;
end;

function TDeepseek.GetFIMRoute: TFIMRoute;
begin
  if not Assigned(FFIMRoute) then
    FFIMRoute := TFIMRoute.CreateRoute(API);
  Result := FFIMRoute;
end;

function TDeepseek.GetKey: string;
begin
  Result := FAPI.APIKey;
end;

function TDeepseek.GetUserRoute: TUserRoute;
begin
  if not Assigned(FUserRoute) then
    FUserRoute := TUserRoute.CreateRoute(API);
  Result := FUserRoute;
end;

function TDeepseek.GetVersion: string;
begin
  Result := VERSION;
end;

procedure TDeepseek.SetBaseUrl(const Value: string);
begin
  FAPI.BaseURL := Value;
end;

procedure TDeepseek.SetKey(const Value: string);
begin
  FAPI.APIKey := Value;
end;


{ TDeepseekFactory }

class function TDeepseekFactory.CreateBetaInstance(
  const AToken: string): IDeepseek;
begin
  Result := TDeepseek.Create(AToken);
  Result.BaseURL := 'https://api.deepseek.com/beta';
end;

class function TDeepseekFactory.CreateInstance(const AToken: string): IDeepseek;
begin
  Result := TDeepseek.Create(AToken);
end;

class function TDeepseekFactory.CreateLMSInstance(
  const URLBase: string): IDeepseek;
begin
  if not URLBase.Trim.IsEmpty then
    begin
      var Base := URLBase.TrimRight(['/']);
      if not Base.EndsWith('/v1', True) then
        Base := Base + '/v1';
      TDeepseekAPI.LocalUrlBase := Base;
    end;
  Result := TDeepseek.Create('', True);
end;

end.
