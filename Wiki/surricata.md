# Nastaveni switche pro monitoring
```
$a = Get-VMSystemSwitchExtensionPortFeature -FeatureId 776e0ba7-94a1-41c8-8f28-951f524251b5
$a.SettingData.MonitorMode = 2
add-VMSwitchExtensionPortFeature -ExternalPort -SwitchName VirtualSwitch01 -VMSwitchExtensionFeature $a
```
- a pak na VM zapnout na sitovem adapteru Destionation jako mirorring
