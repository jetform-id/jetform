defmodule App.PaymentGateway.CreateTransactionResult do
  @enforce_keys [:id, :redirect_url, :data]

  @type t :: %__MODULE__{
          id: String.t(),
          redirect_url: String.t(),
          data: map()
        }
  defstruct [:id, :redirect_url, :data]

  def new(id, redirect_url, data) do
    %__MODULE__{id: id, redirect_url: redirect_url, data: data}
  end
end

defmodule App.PaymentGateway.GetTransactionResult do
  @enforce_keys [
    :data,
    :id,
    :status
  ]

  @type t :: %__MODULE__{
          data: map(),
          type: String.t(),
          id: String.t(),
          status: String.t(),
          status_code: String.t(),
          gross_amount: integer(),
          fee: integer()
        }
  defstruct [
    :data,
    :type,
    :id,
    :status,
    :fraud_status,
    :status_code,
    :gross_amount,
    :fee
  ]
end

defmodule App.PaymentGateway.PaymentChannel do
  @enforce_keys [:code, :name]
  @type t :: %__MODULE__{
          code: String.t(),
          name: String.t()
        }
  defstruct [
    :code,
    :name,
    :description,
    :logo_url,
    :doc_url,
    :trx_fee,
    :trx_fee_type,
    :additional_fee
  ]
end

defmodule App.PaymentGateway.PaymentChannelCategory do
  @enforce_keys [:code, :name, :channels]
  @type t :: %__MODULE__{
          code: String.t(),
          name: String.t(),
          channels: list(App.PaymentGateway.PaymentChannel.t())
        }
  defstruct [:code, :name, :channels]
end

defmodule App.PaymentGateway.ProviderInfo do
  @enforce_keys [:name, :website]

  @type t :: %__MODULE__{
          name: String.t(),
          website: String.t()
        }
  defstruct [:name, :website]

  def new(name, website) do
    %__MODULE__{name: name, website: website}
  end
end

defmodule App.PaymentGateway.Provider do
  @callback id() :: String.t()
  @callback info() :: App.PaymentGateway.ProviderInfo.t()

  @callback config_value(key :: atom()) :: any()
  @callback list_channels() ::
              {:ok, list(App.PaymentGateway.PaymentChannelCategory.t())} | {:error, any()}
  @callback create_redirect_transaction(payload :: map()) ::
              {:ok, App.PaymentGateway.CreateTransactionResult.t()} | {:error, any()}
  @callback create_direct_transaction(payload :: map()) ::
              {:ok, App.PaymentGateway.CreateTransactionResult.t()} | {:error, any()}
  @callback cancel_transaction(id :: String.t()) :: {:ok, any()} | {:error, any()}
  @callback get_transaction(id :: String.t()) ::
              {:ok, App.PaymentGateway.GetTransactionResult.t()} | {:error, any()}
  @callback create_redirect_transaction_payload(
              order :: map(),
              payment :: map(),
              options :: keyword()
            ) :: map()
  @callback create_direct_transaction_payload(
              order :: map(),
              payment :: map(),
              options :: keyword()
            ) :: map()
end
