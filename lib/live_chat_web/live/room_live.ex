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
       total_messages: [],
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
    message = message |> Map.put(:type, :user)

    socket =
      socket
      |> assign(messages: [message], total_messages: socket.assigns.total_messages ++ [message])
      |> push_event("new_message", %{})

    {:noreply, socket}
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

    socket =
      socket
      |> assign(messages: join_messages ++ leave_messages, user_list: user_list)
      |> push_event("new_message", %{})

    {:noreply, socket}
  end

  def display_message(%{type: :system} = assigns) do
  
    text_color =
      case String.contains?(assigns.content, "joined") do
        true -> "text-green-600"
        false -> "text-red-600"
      end
      
    classes = "px-4 py-2 m-2 rounded-lg block rounded-bl-none w-fit italic " <> text_color

    ~H"""
      <span id={@uuid} class={classes}> System: <%= @content %></span>
    """
  end

  def display_message(assigns) do
    ~H"""
      <span id={@uuid} class="break-words max-w-md px-4 py-2 m-2 rounded-lg block rounded-bl-none bg-gray-300 text-gray-600 w-fit"><%= @username %>: <%= @content %></span>
    """
  end
end
