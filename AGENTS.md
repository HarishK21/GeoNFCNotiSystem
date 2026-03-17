# GeoTap Guardian Agent Rules

- Android-first delivery. Treat Android geofencing and Android NFC as the priority integration path.
- Role-based navigation is required. The single app must support Parent/Guardian and Teacher/Staff views.
- Geofence means approaching. Do not treat geofence alone as release authorization.
- NFC means verified. Staff may release a student only after verified on-site status is visible.
- Keep files small and modular. Prefer focused widgets, providers, and models over large mixed files.
- Use Riverpod for state and dependency wiring.
- Use GoRouter for navigation and role shells.
- Validate after each milestone with the strongest available commands.
- If validation fails, stop, fix the failure, and only then move to the next milestone.
- Keep Firebase optional at startup until project configuration is added.
- Preserve iOS compile safety where practical, but do not compromise Android-first implementation decisions.
