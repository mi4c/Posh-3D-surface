
<#PSScriptInfo

.VERSION 1.0

.GUID 33c74633-0fa9-447c-8964-5a3274b09d56

.AUTHOR markus.kalske@hotmail.com

.COMPANYNAME 

.COPYRIGHT Markus Kalske

.TAGS

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 How to create 3D surface 

#> 
Using Assembly PresentationCore
Using Assembly PresentationFramework
Using Namespace System.Windows
Using Namespace System.Windows.Markup
using Namespace System.Windows.Controls
using Namespace System.Windows.Media
using Namespace System.Windows.Media.Media3D
Using Namespace System.Windows.Input
<#
    .SYNOPSIS
    Shows 3D surface
    .DESCRIPTION
    How to draw 3D surface with powershell
    This example is built from instruction examples found at http://csharphelper.com/blog/2014/10/draw-a-3d-surface-with-wpf-xaml-and-c/
    .NOTES
    SCRIPT REVISION NOTES:
    INIT  DATE        VERSION    NOTES
    MK    2019-12-29  1.0        Initial Script Release
#>
#REQUIRES -version 5
function Cleanup-Variables {
    <#
    .SYNOPSIS
    Clean all variables that were loaded and used in this powershell session.
    .DESCRIPTION
    Clean all variables.
    .COMPONENT
    pshTemplate
    .ROLE
    Call this function end of your script.
    .PARAMETER
    
    .EXAMPLE
    
    .NOTES
    SCRIPT REVISION NOTES:
    INIT  DATE        VERSION    NOTES
    MK    2015-08-05  1.0        Initial Script Release

    UNIT TEST AND VERIFICATION INSTRUCTIONS:
    
    #>
    Get-Variable -ErrorAction SilentlyContinue | Where-Object { $startupVariables -notcontains $_.Name } | % { Remove-Variable -Name "$($_.Name)" -Force -Scope "global" -ErrorAction SilentlyContinue }
} # function Cleanup-Variables

[system.windows.Window] $mainWindow = [System.Windows.Markup.XamlReader]::Parse(@'
    <Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="howto_draw_surface"
    Height="500" Width="500">
    <Grid>
        <Viewport3D Grid.Row="0" Grid.Column="0"
            Name="MainViewport" />
    </Grid>
    </Window>
'@)


[Double]$Global:CameraPhi = [Math]::PI / 6.0   # 30 degrees
[Double]$Global:CameraTheta = [Math]::PI / 6.0 # 30 degrees
[Double]$Global:CameraR = 3.0

$MainModel3Dgroup = New-Object System.Windows.Media.Media3D.Model3DGroup
$TheCamera = New-Object System.Windows.Media.Media3D.PerspectiveCamera
$TheCamera.FieldOfView = 60

# Change in CameraPhi up/down Option Constant prevents this value to be changed
New-Variable -Name CameraDPhi -Value 0.05 -Option Constant
New-Variable -Name CameraDTheta -Value 0.05 -Option Constant
New-Variable -Name CameraDR -Value 0.05 -Option Constant

Function DefineLights{
    $ambient_light = New-Object System.Windows.Media.Media3D.AmbientLight -property @{Color = 'DarkGray'}
    $directional_light = New-Object System.Windows.Media.Media3D.DirectionalLight -Property @{Color = 'DarkGray'
                                                                                              Direction = $(New-Object System.Windows.Media.Media3D.Vector3D(-1.0,-3.0,-2.0)) #'-1.0,-3.0,-2.0'
    }
    $MainModel3Dgroup.Children.Add($ambient_light)
    $MainModel3Dgroup.Children.Add($directional_light)
}

Function F_Surface_XY{
    Param(
        [Double]$x,
        [Double]$z        
    )
    [Double]$two_pi = 2*3.14159265
    [Double]$r2 = $x * $x + $z *$z
    [Double]$r = [Math]::Sqrt($r2)
    [Double]$theta = [Math]::Atan2($z,$x)
    $Result = [Math]::Exp(-$r2) * [Math]::Sin($two_pi * $r) * [Math]::Cos(3 * $theta)
    Return $Result
}

Function DefineModel{
    Param(
        $Model3DGroup
    )
    $mesh = New-Object System.Windows.Media.Media3D.MeshGeometry3D 
    # surface's points and triangles
    [Double]$xmin = -1.5
    [Double]$xmax = 1.5
    [Double]$dx = 0.05
    [Double]$zmin = -1.5
    [Double]$zmax = 1.5
    [Double]$dz = 0.05
    For([Double]$x = $xmin; $x -le $xmax - $dx; $x += $dx){
        For([Double]$z = $zmin; $z -le $zmax - $dz; $z += $dx){
            # Points at the corners of the surface
            # over (x,z) - (x + dx, z + dz)
            # F_Surface_XY
            # $a =New-Object System.Windows.Media.Media3D.Point3D
            $p00 = New-Object System.Windows.Media.Media3D.Point3D($x,(F_Surface_XY -x $x -z $z),$z)
            $p10 = New-Object System.Windows.Media.Media3D.Point3D(($x + $dx),(F_Surface_XY -x $x -z $z),$z)
            $p01 = New-Object System.Windows.Media.Media3D.Point3D($x,(F_Surface_XY -x $x -z $z),($z + $dz))
            $p11 = New-Object System.Windows.Media.Media3D.Point3D(($x + $dx),(F_Surface_XY -x ($x + $dx) -z ($z + $dz)),($z + $dz))
            AddTriangle -mesh $mesh -point1 $p00 -point2 $p01 -point3 $p11
            AddTriangle -mesh $mesh -point1 $p00 -point2 $p11 -point3 $p10
        }
    }
    $surface_material = New-Object System.Windows.Media.Media3D.DiffuseMaterial -Property @{Brush = 'Orange'}
    $Surface_Model = New-Object System.Windows.Media.Media3D.GeometryModel3D -ArgumentList $mesh,$surface_material
    # Make the surface visible from both sides, if not used then bottom is not visible
    $Surface_Model.BackMaterial = $surface_material
    $MainModel3Dgroup.Children.Add($Surface_Model)
}
# Calculate points from array
# Really slow
# Over 5 minutes to load
<#
Function AddPoint{
    Param(
        [Point3DCollection]$points,
        [Point3D]$Point
    )
    for ([int]$i = 0; $i -lt $points.Count; $i++){
        if (($point.X -eq $points[$i].X) -and
            ($point.Y -eq $points[$i].Y) -and
            ($point.Z -eq $points[$i].Z)){
                return $i;
        }
    }

    $points.Add($point);
    return $points.Count - 1;
}
#>

# Reverse calculate points from array
# Faster as when reading from the end the added point compare is found faster than starting from the begin of the array 
# Over 3 minutes to load
<#
Function AddPoint{
    Param(
        [Point3DCollection]$points,
        [Point3D]$Point
    )
    for ([int]$i = $points.count-1; $i -ge 0; $i--){
        if (($point.X -eq $points[$i].X) -and
            ($point.Y -eq $points[$i].Y) -and
            ($point.Z -eq $points[$i].Z)){
                Return $i
        }
    }
    # No point found, create it.
    $points.Add($point)
    Return ($points.Count - 1)
}
#>

$PointDictionary = @{}
# Hashmap power, no calculation just index and use
# 15-18 seconds
Function AddPoint{
    Param(
        [Point3DCollection]$points,
        [Point3D]$point
    )

    # If the point is in the point dictionary,
    # return its saved index.
    if ($PointDictionary.ContainsKey($point)){
        return $PointDictionary[$point];
    }
    # We didn't find the point. Create it.
    $points.Add($point);
    $PointDictionary.Add($point, $points.Count - 1);
    return $points.Count - 1;
}

Function AddTriangle{
    Param(
        [System.Windows.Media.Media3D.MeshGeometry3D]$mesh,
        [System.Windows.Media.Media3D.Point3D]$point1,
        [System.Windows.Media.Media3D.Point3D]$point2,
        [System.Windows.Media.Media3D.Point3D]$point3
    )
        
    [Int]$Index1 = AddPoint -points $mesh.Positions -point $point1
    [Int]$Index2 = AddPoint -points $mesh.Positions -point $point2
    [Int]$Index3 = AddPoint -points $mesh.Positions -point $point3
    $Mesh.TriangleIndices.Add($Index1)
    $Mesh.TriangleIndices.Add($Index2)
    $Mesh.TriangleIndices.Add($Index3)
}

Function PositionCamera{
    [Double]$y = $CameraR * [Math]::Sin($CameraPhi)
    [Double]$hyp = $CameraR * [Math]::Cos($CameraPhi)
    [Double]$x = $hyp * [Math]::Cos($CameraTheta)
    [Double]$z = $hyp * [Math]::Sin($CameraTheta)
    if(-not $position){
        $position = New-Object System.Windows.Media.Media3D.Point3D($x,$y,$z)
    } else {
        $position = $x,$y,$z
    }
    if(-not $lookdirection){
        $lookdirection = New-Object System.Windows.Media.Media3D.Vector3D(-$x,-$y,-$z)
    } else {
        $lookdirection = -$x,-$y,-$z
    }
    $TheCamera.Position = $position
    # The point of camera looks at
    $TheCamera.LookDirection = $lookdirection
    if(-not $outofScope){
        # Vertical axis of camera with Horizontal axis
        $TheCamera.UpDirection = "0,1,0"
    }
    elseif($outofScope){
        # Reverse Vertical axis of camera with Horizontal axis
        $TheCamera.UpDirection = "0,-1,0"
    }
}

[System.Windows.EventManager]::RegisterClassHandler([system.windows.Window], [Keyboard]::KeyDownEvent , [KeyEventHandler] {
    Param ([Object] $sender, [System.Windows.Input.KeyEventArgs]$eventArgs)
    Switch ($eventArgs.key){
        'up'{
            $Global:CameraPhi = $CameraPhi + $CameraDPhi
            if($CameraPhi -gt ([Math]::PI / 2.0) -and -not($CameraPhi -lt (-[Math]::PI / 2.0))){
                if($CameraPhi -gt (3*[Math]::PI / 2.0) -and -not($CameraPhi -lt (3*-[Math]::PI / 2.0) )){
                    # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                    $Global:CameraPhi = (-[Math]::PI / 2.0)
                    # Set positive angle marker
                    $outofScope = $False
                    Break;
                }
                # Set negative angle marker
                $outofScope = $true
            }
            elseif($CameraPhi -lt (-[Math]::PI / 2.0) -and -not($CameraPhi -gt ([Math]::PI / 2.0))){
                # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                if($CameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($CameraPhi -gt (3*[Math]::PI / 2.0))){
                    $Global:CameraPhi = ([Math]::PI / 2.0)
                    $outofScope = $False
                    Break;
                }
                $outofScope = $true
            } else {
                # Set positive angle marker
                $outofScope = $false
            }
            Break;
        }
        'Down'{
            $Global:CameraPhi = $CameraPhi + -$CameraDPhi
            if($CameraPhi -lt (-[Math]::PI / 2.0) -and -not($CameraPhi -gt ([Math]::PI / 2.0))){
                # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                if($CameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($CameraPhi -gt (3*[Math]::PI / 2.0))){
                    $Global:CameraPhi = ([Math]::PI / 2.0)
                    $outofScope = $False
                    Break;
                }
                $outofScope = $true
            }
            elseif($CameraPhi -gt ([Math]::PI / 2.0) -and -not($CameraPhi -lt (-[Math]::PI / 2.0))){
                if($CameraPhi -gt (3*[Math]::PI / 2.0) -and -not($CameraPhi -lt (3*-[Math]::PI / 2.0) )){
                    # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                    $Global:CameraPhi = (-[Math]::PI / 2.0)
                    # Set positive angle marker
                    $outofScope = $False
                    Break;
                }
                # Set negative angle marker
                $outofScope = $true
            } else {
                # Set positive angle marker
                $outofScope = $false
            }
            Break;
        }
        'Left'{
            $Global:CameraTheta = $CameraTheta + $CameraDTheta;
            if($CameraPhi -gt ([Math]::PI / 2.0) -and -not($CameraPhi -lt (-[Math]::PI / 2.0))){
                if($CameraPhi -gt (3*[Math]::PI / 2.0) -and -not($CameraPhi -lt (3*-[Math]::PI / 2.0) )){
                    # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                    $Global:CameraPhi = (-[Math]::PI / 2.0)
                    # Set positive angle marker
                    $outofScope = $False
                    Break;
                }
                # Set negative angle marker
                $outofScope = $true
            }
            elseif($CameraPhi -lt (-[Math]::PI / 2.0) -and -not($CameraPhi -gt ([Math]::PI / 2.0))){
                # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                if($CameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($CameraPhi -gt (3*[Math]::PI / 2.0))){
                    $Global:CameraPhi = ([Math]::PI / 2.0)
                    $outofScope = $False
                    Break;
                }
                $outofScope = $true
            } else {
                # Set positive angle marker
                $outofScope = $false
            }
            break;
        }
        'Right'{
            $Global:CameraTheta = $CameraTheta - $CameraDTheta;
            if($CameraPhi -gt ([Math]::PI / 2.0) -and -not($CameraPhi -lt (-[Math]::PI / 2.0))){
                if($CameraPhi -gt (3*[Math]::PI / 2.0) -and -not($CameraPhi -lt (3*-[Math]::PI / 2.0) )){
                    # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                    $Global:CameraPhi = (-[Math]::PI / 2.0)
                    # Set positive angle marker
                    $outofScope = $False
                    Break;
                }
                # Set negative angle marker
                $outofScope = $true
            }
            elseif($CameraPhi -lt (-[Math]::PI / 2.0) -and -not($CameraPhi -gt ([Math]::PI / 2.0))){
                # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                if($CameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($CameraPhi -gt (3*[Math]::PI / 2.0))){
                    $Global:CameraPhi = ([Math]::PI / 2.0)
                    $outofScope = $False
                    Break;
                }
                $outofScope = $true
            } else {
                # Set positive angle marker
                $outofScope = $false
            }
            Break;
        }
        'W'{
            $Global:CameraR -= $CameraDR;
            if ($CameraR -lt $CameraDR){
                $CameraR = $CameraR - $CameraDR;
            }
            if($CameraPhi -gt ([Math]::PI / 2.0) -and -not($CameraPhi -lt (-[Math]::PI / 2.0))){
                if($CameraPhi -gt (3*[Math]::PI / 2.0) -and -not($CameraPhi -lt (3*-[Math]::PI / 2.0) )){
                    # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                    $Global:CameraPhi = (-[Math]::PI / 2.0)
                    # Set positive angle marker
                    $outofScope = $False
                    Break;
                }
                # Set negative angle marker
                $outofScope = $true
            }
            elseif($CameraPhi -lt (-[Math]::PI / 2.0) -and -not($CameraPhi -gt ([Math]::PI / 2.0))){
                # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                if($CameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($CameraPhi -gt (3*[Math]::PI / 2.0))){
                    $Global:CameraPhi = ([Math]::PI / 2.0)
                    $outofScope = $False
                    Break;
                }
                $outofScope = $true
            } else {
                # Set positive angle marker
                $outofScope = $false
            }
            Break;
        }
        'S'{
            $Global:CameraR = $CameraR + $CameraDR;
            if($CameraPhi -gt ([Math]::PI / 2.0) -and -not($CameraPhi -lt (-[Math]::PI / 2.0))){
                if($CameraPhi -gt (3*[Math]::PI / 2.0) -and -not($CameraPhi -lt (3*-[Math]::PI / 2.0) )){
                    # starting point was 1/4, so we need to reset camera after we pass 3/4 of the round
                    $Global:CameraPhi = (-[Math]::PI / 2.0)
                    # Set positive angle marker
                    $outofScope = $False
                    Break;
                }
                # Set negative angle marker
                $outofScope = $true
            }
            elseif($CameraPhi -lt (-[Math]::PI / 2.0) -and -not($CameraPhi -gt ([Math]::PI / 2.0))){
                # starting point was 1/4, so we need to reset camera after we pass negative 3/4 of the round
                if($CameraPhi -lt (3*-[Math]::PI / 2.0) -and -not($CameraPhi -gt (3*[Math]::PI / 2.0))){
                    $Global:CameraPhi = ([Math]::PI / 2.0)
                    $outofScope = $False
                    Break;
                }
                $outofScope = $true
            } else {
                # Set positive angle marker
                $outofScope = $false
            }
            Break;
        }
        default{
            $nochange = $true
            break;
        }
    }
    if(-Not $nochange){
        PositionCamera
    } else {
        $nochange = $false
    }
})

$mainWindow.Add_Loaded({
    $mainWindow.Content.ShowGridLines = $true
    $mainWindow.Content.Background = 'DarkBlue'
    $MainViewPort = $mainWindow.FindName('MainViewport')
    $MainViewport.Camera = $TheCamera
    PositionCamera
    DefineLights
    DefineModel -Model3DGroup $MainModel3Dgroup
    $model_visual = New-Object System.Windows.Media.Media3D.ModelVisual3D
    $model_visual.Content = $MainModel3Dgroup
    $MainViewport.Children.Add($model_visual)
})

$mainWindow.ShowDialog() | Out-Null
Cleanup-Variables



