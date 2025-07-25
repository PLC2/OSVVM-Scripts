#  File Name:         VendorScripts_VSimSA.tcl
#  Purpose:           Scripts for running simulations
#  Revision:          OSVVM MODELS STANDARD VERSION
# 
#  Maintainer:        Jim Lewis      email:  jim@synthworks.com 
#  Contributor(s):            
#     Jim Lewis      email:  jim@synthworks.com   
# 
#  Description
#      TCL abstraction layer to run OSVVM pro scripts with
#      running ActiveHDL from a TCL shell. 
#    
#  Developed by: 
#        SynthWorks Design Inc. 
#        VHDL Training Classes
#        OSVVM Methodology and Model Library
#        11898 SW 128th Ave.  Tigard, Or  97223
#        http://www.SynthWorks.com
# 
#  Revision History:
#    Date      Version    Description
#     5/2024   2024.05    Added ToolVersion variable 
#     5/2022   2022.05    Coverage report name based on TestCaseName rather than LibraryUnit
#                         Updated variable naming 
#     2/2022   2022.02    Added Coverage Collection
#    12/2021   2021.12    Updated to use relative paths.
#     3/2021   2021.03    In Simulate, added optional scripts to run as part of simulate
#     2/2021   2021.02    Refactored variable settings to here from ToolConfiguration.tcl
#     7/2020   2020.07    Refactored tool execution for simpler vendor customization
#     1/2020   2020.01    Updated Licenses to Apache
#     2/2019   Beta       Project descriptors in .pro which execute 
#                         as TCL scripts in conjunction with the library 
#                         procedures
#    11/2018   Alpha      Project descriptors in .files and .dirs files
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2018 - 2021 by SynthWorks Design Inc.  
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      https://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

# -------------------------------------------------
# Tool Settings
#
  variable ToolType    "simulator"
  variable ToolVendor  "Aldec"
  variable ToolName    "ActiveASim"
  variable simulator   $ToolName ; # Variable simulator is deprecated.  Use ToolName instead 
  variable ToolVersion [lindex [split [exec vsim -version]] 4]
#  variable ToolVersion [lindex [split $version] [llength $version]-1]
  variable ToolNameVersion ${ToolName}-${ToolVersion}
#   puts $ToolNameVersion

  if {[expr [string compare $ToolVersion "12.0"] >= 0]} {
    SetVHDLVersion 2019
    variable Support2019FilePath "true"
  }

  variable FunctionalCoverageIntegratedInSimulator "Aldec"
  
#  if {[batch_mode]} {
    variable NoGui "true"
#  } else {
#    variable NoGui "false"
#  }

# -------------------------------------------------
# StartTranscript / StopTranscxript
#
# proc vendor_StartTranscript {FileName} {
#   transcript off
#   puts "transcript to $FileName"
#   transcript to $FileName
# }
# 
# proc vendor_StopTranscript {FileName} {
#   transcript to -off
# }

# -------------------------------------------------
# IsVendorCommand
#
proc IsVendorCommand {LineOfText} {

  return [regexp {^alib |^amap |^acom |^alog |^asim |^vlib |^vmap |^vcom |^vlog |^vsim |^run |^acdb } $LineOfText] 
}

# -------------------------------------------------
# SetCoverageAnalyzeOptions
# SetCoverageCoverageOptions
#
proc vendor_SetCoverageAnalyzeDefaults {} {
  variable CoverageAnalyzeOptions
#  set CoverageAnalyzeOptions "-coverage sbmec"
  set CoverageAnalyzeOptions "-coverage sbm"
}

proc vendor_SetCoverageSimulateDefaults {} {
  variable CoverageSimulateOptions
#  set CoverageSimulateOptions "-acdb -acdb_cov sbmec -cc_all"
  set CoverageSimulateOptions "-acdb -acdb_cov sbm -cc_all"
}


# -------------------------------------------------
# Library
#
proc vendor_library {LibraryName PathToLib} {
  set PathAndLib ${PathToLib}/${LibraryName}

  if {![file exists ${PathAndLib}]} {
    puts "vlib    ${PathAndLib}"
    exec     vlib    ${PathAndLib}
    # after 1000
  }
  puts "vmap    $LibraryName  ${PathAndLib}"
  exec  vmap    $LibraryName  ${PathAndLib}
}

proc vendor_LinkLibrary {LibraryName PathToLib} {
  set PathAndLib ${PathToLib}/${LibraryName}

  if {[file exists ${PathAndLib}]} {
    set ResolvedLib ${PathAndLib}
  } else {
    set ResolvedLib ${PathToLib}
  }
  puts "vmap    $LibraryName  ${ResolvedLib}"
  exec vmap    $LibraryName  ${ResolvedLib}
}

proc vendor_UnlinkLibrary {LibraryName PathToLib} {
  exec vmap -del ${LibraryName}
}

# -------------------------------------------------
# analyze
#
proc vendor_analyze_vhdl {LibraryName FileName args} {
  variable VhdlVersion
  
  # For now, do not use -dbg flag with coverage.
  set DebugOptions ""
  
  set  AnalyzeOptions [concat -${VhdlVersion} {*}${DebugOptions} -relax -work ${LibraryName} {*}${args} ${FileName}]
  
  puts "vcom $AnalyzeOptions"
#  exec  vcom {*}$AnalyzeOptions
  
  set ErrorCode [catch {exec vcom {*}$AnalyzeOptions} CatchMessage] 
  if {$ErrorCode != 0} {
    PrintWithPrefix "Error:" $CatchMessage
    puts $::errorInfo
    error "Failed: analyze $FileName"
  } else {
    puts $CatchMessage
  }
}

proc vendor_analyze_verilog {LibraryName FileName args} {
  set  AnalyzeOptions [concat [CreateVerilogLibraryParams "-l "] -work ${LibraryName} {*}${args} ${FileName}]
  puts "vlog $AnalyzeOptions"
#  exec  vlog {*}$AnalyzeOptions
  
  set ErrorCode [catch {exec vlog {*}$AnalyzeOptions} CatchMessage] 
  if {$ErrorCode != 0} {
    PrintWithPrefix "Error:" $CatchMessage
    puts $::errorInfo
    error "Failed: analyze $FileName"
  } else {
    puts $CatchMessage
  }
}

# -------------------------------------------------
proc NoNullRangeWarning  {} {
  return "-nowarn COMP96_0119"
}

# -------------------------------------------------
# End Previous Simulation
#
proc vendor_end_previous_simulation {} {
  # endsim
}  

# -------------------------------------------------
# Simulate
#
proc vendor_simulate {LibraryName LibraryUnit args} {
  variable OsvvmScriptDirectory
  variable SimulateTimeUnits
  variable ToolVendor
  variable TestSuiteName
  variable TestCaseFileName
  global aldec            ; #  required for matlab cosim

  # Create the script files
  set ErrorCode [catch {vendor_CreateSimulateDoFile $LibraryUnit OsvvmSimRun.tcl} CatchMessage]
  if {$ErrorCode != 0} {
    PrintWithPrefix "Error:" $CatchMessage
    puts $::errorInfo
    error "Failed: vendor_CreateSimulateDoFile $LibraryUnit"
  } 

#  puts "vendor simulate LN=$LibraryName LU=$LibraryUnit A=$args"
  set SimulateOptions [concat -c {*}${args} {*}${::osvvm::GenericOptions} -t $SimulateTimeUnits -lib ${LibraryName} ${LibraryUnit} ${::osvvm::SecondSimulationTopLevel}]

  puts "vsim ${SimulateOptions}"
##  exec  vsim {*}${SimulateOptions} -tcl "OsvvmSimRun.tcl"
  
  set ErrorCode [catch {exec  vsim {*}${SimulateOptions} -tcl "OsvvmSimRun.tcl"} CatchMessage] 
  if {$ErrorCode != 0} {
    PrintWithPrefix "Error:" $CatchMessage
    puts $::errorInfo
    error "Failed: simulate $LibraryUnit"
  } else {
    puts $CatchMessage
  }
}

# -------------------------------------------------
# vendor_CreateSimulateDoFile
#
proc vendor_CreateSimulateDoFile {LibraryUnit ScriptFileName} {
  variable ScriptFile 
  
  # Open File
  set ScriptFile [open $ScriptFileName w]
  
  # Do Vendor Simulate pre-run stuff here
  
#?? is it possible that we want to save waves in a batch simulator

  SimulateCreateDoFile $LibraryUnit

  puts  $ScriptFile "run -all" 
  
  # Save Coverage Information
  if {$::osvvm::CoverageEnable && $::osvvm::CoverageSimulateEnable} {
    puts $ScriptFile "acdb save -o ${::osvvm::CoverageDirectory}/${TestSuiteName}/${TestCaseFileName}.acdb -testname ${TestCaseFileName}"
  }
  
#  puts  $ScriptFile "quit" 
  close $ScriptFile
}


# -------------------------------------------------
proc vendor_generic {Name Value} {
  
  return "-g${Name}=${Value}"
}

# -------------------------------------------------
# Merge Coverage
#
proc vendor_MergeCodeCoverage {TestSuiteName CoverageDirectory BuildName} { 
  set CoverageFileBaseName [file join ${CoverageDirectory} ${BuildName} ${TestSuiteName}]
  set CovFiles [glob -nocomplain ${CoverageDirectory}/${TestSuiteName}/*.acdb]
  if {$CovFiles ne ""} {
    exec vsim -c -tcl "acdb merge -o ${CoverageFileBaseName}.acdb -i {*}[join $CovFiles " -i "]"
  }
}

proc vendor_ReportCodeCoverage {TestSuiteName CodeCoverageDirectory} { 
  set CodeCovResultsDir ${CodeCoverageDirectory}/${TestSuiteName}_code_cov
  if {[file exists ${CodeCovResultsDir}.html]} {
    file delete -force -- ${CodeCovResultsDir}.html
  }
  if {[file exists ${CodeCovResultsDir}_files]} {
    file delete -force -- ${CodeCovResultsDir}_files
  }
  exec vsim -c -tcl "acdb report -html -i ${CodeCoverageDirectory}/${TestSuiteName}.acdb -o ${CodeCovResultsDir}.html"
}

proc vendor_GetCoverageFileName {TestName} { 
  set CoverageFileName ${TestName}_code_cov.html
  return $CoverageFileName
}
