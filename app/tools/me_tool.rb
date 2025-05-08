# frozen_string_literal: true

class MeTool < ApplicationTool
  description 'Get the current logged in user'

  def call
    me = current_user
    JSON.generate({
      id: me.id,
      email: me.email,
    })
  end
end
