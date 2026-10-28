function controller = createController(config)
%CREATECONTROLLER Production factory shared by the CLI and consumer tests.
controller = wss.StimulationController(config);
end
