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

defmodule App.PaymentGateway.Provider do
  @callback config_value(key :: atom()) :: any()
  @callback name() :: String.t()
  @callback create_transaction(payload :: map()) ::
              {:ok, App.PaymentGateway.CreateTransactionResult.t()} | {:error, any()}
  @callback cancel_transaction(id :: String.t()) :: {:ok, any()} | {:error, any()}
  @callback get_transaction(id :: String.t()) :: {:ok, any()} | {:error, any()}
  @callback create_transaction_payload(
              order :: map(),
              payment :: map(),
              options :: keyword()
            ) :: map()
end
