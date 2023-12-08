defmodule AppWeb.Layouts do
  use AppWeb, :html

  embed_templates "layouts/*"
  embed_templates "layouts/partials/*"
end
