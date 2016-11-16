-----------------------------------------------------
-- Define your variables here
-----------------------------------------------------
local script = libs.script;
local ffi = require("ffi");
ffi.cdef[[
bool LockWorkStation();
int ExitWindowsEx(int uFlags, int dwReason);
bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);
]]
local PowrProf = ffi.load("PowrProf");
local w_minutes = 0;
local f_minutes = 0;
local turnOffLightsAfterWait = 1;



actions.fade = function ()
	layout.message.text = "Fading over total ".. w_minutes + f_minutes .. " minutes";
	script.powershell("./installAudioApi.ps1 ".. w_minutes .." ".. f_minutes .. " " .. turnOffLightsAfterWait);
	PowrProf.SetSuspendState(false, true, false);
end

actions.f_update = function (text)
	f_minutes = tonumber(text);
end

actions.w_update = function (text)
	w_minutes = tonumber(text);
end

actions.k_changed = function (checked)

	if checked then 
		layout.lightsToggle.text = "Turn lights OFF after WAIT."
		turnOffLightsAfterWait = 1;
	else 
		layout.lightsToggle.text = "Turn lights OFF after FADE."
		turnOffLightsAfterWait = 0;
	end
end