defmodule ExGraphQLTest do
  use ExSpec, async: true

  it "can do a simple query" do
    query = """
    query GimmeFoo {
      thing(id: "foo") {
        name
      }
    }
    """
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}, errors: []}} = ExGraphQL.run(Things.schema, query)
  end

  it "can identify a bad field" do
    query = """
    {
      thing(id: "foo") {
        name
        bad
      }
    }
    """
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo"}}, errors: [%{message: "Field `bad': Not present in schema", locations: [%{line: 4, column: 0}]}]}} = ExGraphQL.run(Things.schema, query)
  end

  it "gives nice errors for bad resolutions" do
    query = """
    {
      bad_resolution
    }
    """
    assert {:ok, %{data: %{},
                   errors: [%{message: "Field `bad_resolution': Did not resolve to match {:ok, _} or {:error, _}", locations: _}]}} = ExGraphQL.run(Things.schema, query)
  end

  it "returns the correct results for an alias" do
    query = """
    query GimmeFooByAlias {
      widget: thing(id: "foo") {
        name
      }
    }
    """
    assert {:ok, %{data: %{"widget" => %{"name" => "Foo"}}, errors: []}} = ExGraphQL.run(Things.schema, query)
  end

  it "returns nested objects" do
    query = """
    query GimmeFooWithOtherThing {
      thing(id: "foo") {
        name
        other_thing {
          name
        }
      }
    }
    """
    assert {:ok, %{data: %{"thing" => %{"name" => "Foo", "other_thing" => %{"name" => "Bar"}}}, errors: []}} = ExGraphQL.run(Things.schema, query)
  end

  it "can provide context" do
    query = """
      query GimmeThingByContext {
        thingByContext {
          name
        }
      }
    """
    assert {:ok, %{data: %{"thingByContext" => %{"name" => "Bar"}}, errors: []}} = ExGraphQL.run(Things.schema, query, context: %{thing: "bar"})
    assert {:ok, %{data: %{}, errors: [%{message: "Field `thingByContext': No :id context provided"}]}} = ExGraphQL.run(Things.schema, query)
  end

  it "can use variables" do
    query = """
    query GimmeThingByVariable($thingId: String!) {
      thing(id: $thingId) {
        name
      }
    }
    """
    result = ExGraphQL.run(Things.schema, query, variables: %{"thingId" => "bar"})
    assert {:ok, %{data: %{"thing" => %{"name" => "Bar"}}, errors: []}} = result
  end

  it "reports missing, required variable values" do
    query = """
      query GimmeThingByVariable($thingId: String!, $other: String!) {
        thing(id: $thingId) {
          name
        }
      }
    """
    result = ExGraphQL.run(Things.schema, query, variables: %{thingId: "bar"})
    assert {:ok, %{data: %{"thing" => %{"name" => "Bar"}}, errors: [%{message: "Variable `other' (String): Not provided"}]}} = result
  end

end
