defmodule Lucidboard.Twiddler do
  @moduledoc """
  A context for board operations
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias Lucidboard.{Board, BoardRole, Event}
  alias Lucidboard.Repo
  alias Lucidboard.Twiddler.{Actions, Op}

  @type action :: {atom, keyword | map}
  @type meta :: map
  @type action_ok_or_error ::
          {:ok, Board.t(), function, meta, Event.t()} | {:error, String.t()}

  @spec act(Board.t(), action, keyword) :: action_ok_or_error
  def act(board, action, opts \\ [])

  def act(%Board{} = board, {action_name, args}, opts) when is_list(args) do
    act(board, {action_name, Enum.into(args, %{})}, opts)
  end

  def act(%Board{} = board, {action_name, args}, opts)
      when is_atom(action_name) and is_map(args) do
    with true <- function_exported?(Actions, action_name, 3) || :no_action,
         {:ok, _, _, _, _} = res <-
           apply(Actions, action_name, [board, args, opts]) do
      res
    else
      :unauthorized ->
        {:ok, board, nil, nil, nil}

      :noop ->
        {:ok, board, nil, nil, nil}

      :no_action ->
        IO.puts("Action not implemented: #{inspect(action_name)}")
        {:ok, board, nil, nil, nil}

      %Changeset{} = cs ->
        {:error, cs}
    end
  end

  @doc "Get a board by its id"
  @spec by_id(integer) :: Board.t() | nil
  def by_id(id) do
    board =
      Repo.one(
        from(board in Board,
          where: board.id == ^id,
          left_join: board_roles in assoc(board, :board_roles),
          left_join: role_users in assoc(board_roles, :user),
          left_join: columns in assoc(board, :columns),
          left_join: piles in assoc(columns, :piles),
          left_join: cards in assoc(piles, :cards),
          left_join: likes in assoc(cards, :likes),
          preload: [
            columns: {columns, piles: {piles, cards: {cards, likes: likes}}},
            board_roles: {board_roles, user: role_users}
          ]
        )
      )

    if board, do: sort_board(board), else: nil
  end

  @doc "Sort all the columns, piles, and cards by their `:pos` fields"
  @spec sort_board(Board.t()) :: Board.t()
  def sort_board(%Board{} = board) do
    cols =
      Enum.reduce(board.columns, [], fn col, acc_cols ->
        piles =
          Enum.reduce(col.piles, [], fn pile, acc_piles ->
            cards =
              pile.cards
              |> Enum.map(&Op.sort_likes/1)
              |> Enum.sort(&(&1.pos < &2.pos))

            [%{pile | cards: cards} | acc_piles]
          end)

        piles = Enum.sort(piles, &(&1.pos < &2.pos))
        [%{col | piles: piles} | acc_cols]
      end)

    cols = Enum.sort(cols, &(&1.pos < &2.pos))
    %{board | columns: cols}
  end

  @doc "Get a list of board records"
  @spec boards(integer, String.t()) :: [Board.t()]
  def boards(page_index \\ 1, query \\ "") do
    query =
      from(b in Board,
        left_join: u in assoc(b, :user),
        where:
          ilike(b.title, ^"%#{query}%") or
            ilike(u.name, ^"%#{query}%") or
            ilike(u.full_name, ^"%#{query}%"),
        order_by: [desc: b.updated_at],
        preload: :user
      )

    Repo.paginate(query, page: page_index)
  end

  @doc """
  Insert a board record

  Creates 2 records: the Board and the BoardRole for the creator
  """
  @spec insert(Board.t() | Ecto.Changeset.t(Board.t())) ::
          {:ok, Board.t()} | {:error, any}
  def insert(%Board{user: user, user_id: user_id} = board) do
    tx_fn = fn ->
      board_role = BoardRole.new(user_id: user_id || user.id, role: :owner)
      tail = with %Ecto.Association.NotLoaded{} <- board.board_roles, do: []
      Repo.insert(%{board | board_roles: [board_role | tail]})
    end

    with {:ok, {:ok, the_board}} <- Repo.transaction(tx_fn) do
      {:ok, Repo.preload(the_board, :user)}
    end
  end
end
