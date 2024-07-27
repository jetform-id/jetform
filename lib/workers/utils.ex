defmodule Workers.Utils do
  def email_signature(user) do
    user_brand_info =
      Enum.reduce([:brand_name, :brand_email, :brand_phone, :brand_website], [], fn el, acc ->
        if Map.get(user, el), do: acc ++ [Map.get(user, el)], else: acc
      end)

    case Enum.empty?(user_brand_info) do
      true ->
        """
        ---
        JetForm
        Form order produk digital!
        https://www.jetform.me
        """

      false ->
        """
        ---
        #{Enum.join(user_brand_info, "\n")}
        """
    end
  end
end
