defmodule Lucidboard.LiveBoardTest do
  @moduledoc false
  use LucidboardWeb.ConnCase, async: false
  alias Lucidboard.{Board, Column, LiveBoard, Seeds, Twiddler}

  test "basic LiveBoard lifecycle" do
    %{id: user_id} = user = Seeds.get_user()

    # Create a board record in the db
    {:ok, %Board{id: board_id, columns: [%Column{id: column_id}]}} =
      [
        user_id: user_id,
        title: "Awesome",
        columns: [Column.new(title: "foo", pos: 0)]
      ]
      |> Board.new()
      |> Twiddler.insert()

    # Start a liveboard based on it
    {:ok, pid} = LiveBoard.start(board_id)
    assert is_pid(pid)

    # Set the column title
    action = {:update_column, id: column_id, title: "the new title"}
    LiveBoard.call(board_id, {:action, action, user: user})

    # Get the board state from the liveboard
    {:ok,
     %{
       board: %Board{columns: [%Column{title: from_live_board}]},
       events: _events
     }} = LiveBoard.call(board_id, :state)

    # Ensure it's the new title
    assert "the new title" == from_live_board

    # Give the scribe long enough to save and fetch it from the database
    :timer.sleep(50)
    %Board{columns: [%Column{title: from_db}]} = Twiddler.by_id(board_id)

    # Ensure the new title has persisted
    assert "the new title" == from_db

    :ok = LiveBoard.stop(board_id)
  end
end
