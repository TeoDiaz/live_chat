defmodule LiveChatWeb.RoomLive do
  use LiveChatWeb, :live_view
  require Logger

  @impl true
  def mount(%{"id" => room_id} = _params, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug(2)

    if connected?(socket) do
      LiveChatWeb.Endpoint.subscribe(topic)
      LiveChatWeb.Presence.track(self(), topic, username, %{})
    end

    {:ok,
     assign(socket,
       room_id: room_id,
       topic: topic,
       username: username,
       message: "",
       messages: [],
       user_list: [],
       temporary_assigns: [messages: []],
       changeset: %{}
     )}
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    message = %{uuid: UUID.uuid4(), content: message, username: socket.assigns.username}
    LiveChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", message)

    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_update", %{"chat" => %{"message" => message}}, socket) do
    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    {:noreply, assign(socket, messages: [message])}
  end

  @impl true
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username ->
        %{type: :system, uuid: UUID.uuid4(), content: "#{username} joined"}
      end)

    leave_messages =
      leaves
      |> Map.keys()
      |> Enum.map(fn username ->
        %{type: :system, uuid: UUID.uuid4(), content: "#{username} left"}
      end)

    user_list = LiveChatWeb.Presence.list(socket.assigns.topic) |> Map.keys()

    {:noreply, assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)}
  end

  def display_message(%{type: :system} = assigns),
    do: ~H"""
    <p id={@uuid}><em><%= @content %></em></p> 
    """

  def display_message(assigns),
    do: ~H"""
    <p id={@uuid}><strong> <%= @username %></strong>: <%= @content%></p> 
    """
end
