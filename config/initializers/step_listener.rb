# Port Sonic Pi reports chord changes to. Only the server listens: a console or
# a test run must not grab the port.
Rails.application.config.x.osc_port = ENV.fetch("STAGE_OSC_PORT", 4570).to_i

Rails.application.config.after_initialize do
  StepListener.start(Rails.application.config.x.osc_port) if defined?(Rails::Server)
end
