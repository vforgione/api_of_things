defmodule Aot.Meta.Node do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "nodes" do
    field :commissioned_on, :naive_datetime
    field :decommissioned_on, :naive_datetime
    field :description, :string
    field :human_address, :string
    field :location, Geo.PostGIS.Geometry
    field :vsn, :string

    many_to_many :networks, Aot.Meta.Network, join_through: "networks_nodes"
    many_to_many :sensors, Aot.Meta.Sensor, join_through: "nodes_sensors"
    has_many :observations, Aot.Data.Observation
    has_many :raw_observations, Aot.Data.RawObservation
  end

  @doc false
  def changeset(node, attrs) do
    node
    |> cast(attrs, [:id, :vsn, :location, :human_address, :description, :commissioned_on, :decommissioned_on])
    |> validate_required([:id, :vsn, :location, :human_address, :description, :commissioned_on, :decommissioned_on])
  end
end
