defmodule DocumentationTest do
  use ExUnit.Case

  @readme_path Path.join([__DIR__, "..", "README.md"])

  test "README should not contain broken Heroku demo link" do
    readme_content = File.read!(@readme_path)

    # The old Heroku demo at https://gringottspay.herokuapp.com is no longer active
    # and should be removed from the README
    refute String.contains?(readme_content, "gringottspay.herokuapp.com"),
           "README contains broken Heroku demo link that should be removed"
  end
end
