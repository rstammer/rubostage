# The control bar at the top. A Turbo frame that asks again every couple of
# seconds, so the lamps follow along without touching the rest of the page.
class ControlsController < ApplicationController
  def show
    render partial: "controls/panel", locals: {panel: ControlPanel.new}
  end
end
