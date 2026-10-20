# Opens Sonic Pi from the control bar.
class SonicPiController < ApplicationController
  def create
    SonicPiApp.launch if SonicPiApp.state == :off
    redirect_to controls_path
  end
end
