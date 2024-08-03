defmodule App.PaymentGateway.CreateTransactionResult do
  @enforce_keys [:token, :redirect_url]

  @type t :: %__MODULE__{
          token: String.t(),
          redirect_url: String.t()
        }
  defstruct [:token, :redirect_url]

  def new(token, redirect_url) do
    %__MODULE__{token: token, redirect_url: redirect_url}
  end
end

defmodule App.PaymentGateway.GetTransactionResult do
  @enforce_keys [
    :payload,
    :trx_id,
    :trx_status
  ]

  @type t :: %__MODULE__{
          payload: String.t(),
          type: String.t(),
          trx_id: String.t(),
          trx_status: String.t(),
          status_code: String.t(),
          gross_amount: integer(),
          fee: integer()
        }
  defstruct [
    :payload,
    :type,
    :trx_id,
    :trx_status,
    :fraud_status,
    :status_code,
    :gross_amount,
    :fee
  ]
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
  @callback create_transaction(payload :: map()) ::
              {:ok, App.PaymentGateway.CreateTransactionResult.t()} | {:error, any()}
  @callback cancel_transaction(id :: String.t()) :: {:ok, any()} | {:error, any()}
  @callback get_transaction(id :: String.t()) ::
              {:ok, App.PaymentGateway.GetTransactionResult.t()} | {:error, any()}
  @callback create_transaction_payload(
              order :: map(),
              payment :: map(),
              options :: keyword()
            ) :: map()
end
