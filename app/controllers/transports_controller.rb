# The transport bar under the control bar: the footswitches of the song last
# started, on every page. A Turbo frame that asks again every couple of
# seconds, like the lamps above it.
class TransportsController < ApplicationController
  def show
    render partial: "controls/transport", locals: {panel: ControlPanel.new}
  end
end
