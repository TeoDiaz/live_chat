defmodule LiveChatWeb.PageLive do
  use LiveChatWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("random-room", _params, socket) do
    random_slug = "/" <> MnemonicSlugs.generate_slug(4)
    
    {:noreply, push_redirect(socket, to: random_slug)}
  end
end
