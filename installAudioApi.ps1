param($w_minutes, $f_minutes, $turnLightsOffAfterWait)
Write-Host "w_minutes: $w_minutes"
Write-Host "f_minutes: $f_minutes"
Write-Host "turnLightsOffAfterWait: $turnLightsOffAfterWait"
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
  // f(), g(), ... are unused COM method slots. Define these if you care
  int f(); int g(); int h(); int i();
  int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
  int j();
  int GetMasterVolumeLevelScalar(out float pfLevel);
  int k(); int l(); int m(); int n();
  int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
  int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
  int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
  int f(); // Unused
  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }

public class Audio {
  static IAudioEndpointVolume Vol() {
    var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
    IMMDevice dev = null;
    Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
    IAudioEndpointVolume epv = null;
    var epvid = typeof(IAudioEndpointVolume).GUID;
    Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
    return epv;
  }
  public static float Volume {
    get {float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v;}
    set {Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty));}
  }
  public static bool Mute {
    get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
    set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
  }
}
'@


function FadeVolumeLoop(){
	#Setup
	$offsetTickWaitMs = 200;
	$T = $f_minutes * 60 * 1000; #ms
	$S = [Audio]::Volume+0.005; #this is S in S/V*T
	$V = $offsetTickWaitMs * ($S / $T) #this is V in S/V*T
	
	#Wait
	Write-Host "Waiting $w_minutes minutes before starting Fade-effect"
	$wait = $w_minutes * 1000 * 60;
	Start-Sleep -m $wait
	
	#BeginMainLoop
	if($turnLightsOffAfterWait -eq 1) {
		Write-Host "Turn off lights after wait"
		TurnOffLights
	}
	
	Write-Host "Starting fade-effect by $V over $T ms"
	while($true){
		if([Audio]::Volume -lt $V){ 
			return;
		} 
		else {
			[Audio]::Volume = [Audio]::Volume - $V
			$TicksLeft = [Audio]::Volume / $V;
			$SLeft = $V * $TicksLeft;

			Write-Host "Decreasing volume by $V"
			Write-Host "Volume left: $SLeft. Ticks left: $TicksLeft"

			$TLeft = $ticksLeft*$offsetTickWaitMs/1000
			Write-Host "Time left: $TLeft s"
			 
			Write-Host "Waiting $offsetTickWaitMs ms before next tick."
			Start-Sleep -m $offsetTickWaitMs
		}
	}
}

function TurnOffSpeakers(){
    #Speakers
	$postParams = @{toMainPage = 'setOffACCF2399591C'}
    Invoke-WebRequest -Uri http://192.168.0.15:8000/ -Method POST -Body $postParams
}

function TurnOffLights(){
	#Lights
    $postParams = @{toMainPage = 'setOffACCF2399582A'}
    Invoke-WebRequest -Uri http://192.168.0.15:8000/ -Method POST -Body $postParams
}

$sw = [diagnostics.stopwatch]::StartNew()

FadeVolumeLoop
TurnOffSpeakers

if($turnLightsOffAfterWait -eq 0){
	TurnOffLights
}

$sw.Stop()
Write-Host $sw.elapsed

