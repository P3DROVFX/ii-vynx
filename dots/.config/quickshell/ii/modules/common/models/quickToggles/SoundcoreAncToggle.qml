import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions

QuickToggleModel {
    name: Translation.tr("ANC Mode")
    // Consider toggled on when not Normal (i.e. NoiseCanceling or Transparency)
    toggled: SoundcoreService.currentMode !== "Normal"
    
    icon: {
        if (SoundcoreService.currentMode === "Normal") return "hearing";
        if (SoundcoreService.currentMode === "Transparency") return "visibility";
        if (SoundcoreService.currentMode === "NoiseCanceling") return "noise_control_off";
        return "hearing";
    }
    
    statusText: {
        if (SoundcoreService.currentMode === "Normal") return Translation.tr("Normal");
        if (SoundcoreService.currentMode === "Transparency") return Translation.tr("Transparency");
        if (SoundcoreService.currentMode === "NoiseCanceling") return Translation.tr("ANC");
        return Translation.tr("Normal");
    }
    
    mainAction: () => {
        let nextMode = "Normal";
        if (SoundcoreService.currentMode === "Normal") nextMode = "Transparency";
        else if (SoundcoreService.currentMode === "Transparency") nextMode = "NoiseCanceling";
        else if (SoundcoreService.currentMode === "NoiseCanceling") nextMode = "Normal";
        
        SoundcoreService.setMode(nextMode);
    }
    
    tooltipText: Translation.tr("Cycle Soundcore ANC Mode")
}
