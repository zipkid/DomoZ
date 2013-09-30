module Domoz
  require 'rubygems'
  require 'snmp'

  class OwSnmp
    attr_accessor :devices_data, :update_time, :loop_time

    def initialize
      @devices_data = Array.new
      @update_time = Time.now
      @loop_time = 20

      #SNMP::MIB.import_module("OW_Server_MIB_v2.22.mib", './mib/')
      #mib = SNMP::MIB.new
      #mib.load_module("EDS-MIB",'./mib/')
      @snmp_data = [ 'owDeviceROM',
                     'owDeviceHealth',
                     'owDS18S20Temperature',
                     'owDS18S20UserByte1',
                     'owDS18S20UserByte2' ]                  

      ObjectSpace.define_finalizer(self, Proc.new{ if @ows_thread.defined? then @ows_tread.join end })
    end

    def run
      @ows_thread = Thread.new do
        snmp_exec_time = Time.at(0)
        snmp_loop_time = @loop_time
        while true
          if( (Time.now - snmp_exec_time) > snmp_loop_time )
            puts "+ OWS Run"
            #ows = Domoz::OwSnmp.new
            #@temperature_data = ows.get_temp
            get_device_count
            get_devices_data
            @update_time = Time.now
            snmp_exec_time = Time.now
            puts "- OWS run"
          end
        end
      end

    end
    
    def get_temp
      #get_device_count
      #get_devices_data
      #get_ref_temp('C200080230866410')
      @devices_data
    end
    
    private

    def get_ref_temp(rom)
      b = @devices_data.select { |x| x[:owDeviceROM] == rom } 
      b[0][:owDS18S20Temperature]
    end
    
    def get_device_count
      SNMP::Manager.open(:host => '10.0.4.122', :version => :SNMPv1) do |manager|
        response = manager.get(["#{get_oid('owDeviceNumActive')}.0"])
        response.each_varbind do |vb|
          #puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
          @device_count = vb.value
        end
      end
    end

    def get_devices_data
      @devices_data = Array.new()
      i=0
      begin
        @devices_data << get_device_data(i)
        i+=1
      end while i < @device_count
    end

    def get_device_data( index )
      device_data = Hash.new()
      SNMP::Manager.open(:host => '10.0.4.122', :version => :SNMPv1) do |manager|
        response = manager.get([
          "#{get_oid('owDeviceROM')}.#{index}",
          "#{get_oid('owDeviceHealth')}.#{index}",
          "#{get_oid('owDS18S20Temperature')}.#{index}",
          "#{get_oid('owDS18S20UserByte1')}.#{index}",
          "#{get_oid('owDS18S20UserByte2')}.#{index}"
        ])
        i = 0
        response.each_varbind do |vb|
          name = @snmp_data[i]
          i+=1
          if vb.value.asn1_type == 'INTEGER'
            val = vb.value.to_i
          else
            val = vb.value.to_s
          end
          #val = "rom_" + val if name == 'owDeviceROM'
          device_data[name.to_sym] = val
        end
      end
      #puts '---'
      device_data
    end


    def get_oid(oid)
      oids = {
        'owDS18B20Temperature' => '1.3.6.1.4.1.31440.10.5.1.1',
        'owDS18B20PwrSupply' => '1.3.6.1.4.1.31440.10.5.1.5',
        'owEDS0065' => '1.3.6.1.4.1.31440.10.1.10',
        'owDS18S20Table' => '1.3.6.1.4.1.31440.10.6',
        'owEDS0066' => '1.3.6.1.4.1.31440.10.1.11',
        'owTrapDeviceEntry' => '1.3.6.1.4.1.31440.2.2.1',
        'owEDS0067' => '1.3.6.1.4.1.31440.10.1.12',
        'owDS18S20Temperature' => '1.3.6.1.4.1.31440.10.6.1.1',
        'owEDS0068' => '1.3.6.1.4.1.31440.10.1.13',
        'owDS2438Temperature' => '1.3.6.1.4.1.31440.10.8.1.1',
        'owDS2423Entry' => '1.3.6.1.4.1.31440.10.7.1',
        'owDS2438Table' => '1.3.6.1.4.1.31440.10.8',
        'owDeviceTable' => '1.3.6.1.4.1.31440.10.3',
        'owEDS0069' => '1.3.6.1.4.1.31440.10.1.14',
        'owDS2408Table' => '1.3.6.1.4.1.31440.10.9',
        'owDeviceDescription' => '1.3.6.1.4.1.31440.10.3.1.4',
        'owTrapCommunity' => '1.3.6.1.4.1.31440.2.1.1.4',
        'edsMain' => '1.3.6.1.4.1.31440',
        'eFirmwareVersion' => '1.3.6.1.4.1.31440.1.4',
        'owDS2438' => '1.3.6.1.4.1.31440.10.1.5',
        'owDS2406Table' => '1.3.6.1.4.1.31440.10.4',
        'owDS2406Entry' => '1.3.6.1.4.1.31440.10.4.1',
        'owTrapTable' => '1.3.6.1.4.1.31440.2.1',
        'owTrapEntry' => '1.3.6.1.4.1.31440.2.1.1',
        'owDS2450Table' => '1.3.6.1.4.1.31440.10.10',
        'owDeviceType' => '1.3.6.1.4.1.31440.10.3.1.2',
        'owDeviceName' => '1.3.6.1.4.1.31440.10.3.1.3',
        'owDS2438Entry' => '1.3.6.1.4.1.31440.10.8.1',
        'owTrapDeviceHighThreshold' => '1.3.6.1.4.1.31440.2.2.1.6',
        'owDS18S20' => '1.3.6.1.4.1.31440.10.1.4',
        'owDevices' => '1.3.6.1.4.1.31440.10',
        'owDeviceEntry' => '1.3.6.1.4.1.31440.10.3.1',
        'owDeviceROM' => '1.3.6.1.4.1.31440.10.3.1.6',
        'owTrapDeviceROM' => '1.3.6.1.4.1.31440.2.2.1.4',
        'owTrapDeviceEnable' => '1.3.6.1.4.1.31440.2.2.1.2',
        'owDeviceNumActive' => '1.3.6.1.4.1.31440.10.2.1',
        'owDS2406ActivityLatchReset' => '1.3.6.1.4.1.31440.10.4.1.9',
        'owDS18S20UserByte1' => '1.3.6.1.4.1.31440.10.6.1.2',
        'eMIBVersion' => '1.3.6.1.4.1.31440.1.3',
        'owTrapDeviceVariable' => '1.3.6.1.4.1.31440.2.2.1.5',
        'owDS18B20Resolution' => '1.3.6.1.4.1.31440.10.5.1.4',
        'owDS18S20UserByte2' => '1.3.6.1.4.1.31440.10.6.1.3',
        'owDS18B20' => '1.3.6.1.4.1.31440.10.1.3',
        'owTrapEnable' => '1.3.6.1.4.1.31440.2.1.1.2',
        'owTrapDeviceLowThreshold' => '1.3.6.1.4.1.31440.2.2.1.7',
        'owDS18B20UserByte1' => '1.3.6.1.4.1.31440.10.5.1.2',
        'owDS2406PIOBLevel' => '1.3.6.1.4.1.31440.10.4.1.2',
        'owDS18S20Entry' => '1.3.6.1.4.1.31440.10.6.1',
        'owDS2406PIOAActivityLatch' => '1.3.6.1.4.1.31440.10.4.1.5',
        'owDS2406PIOAFlipFlop' => '1.3.6.1.4.1.31440.10.4.1.3',
        'owDS18B20UserByte2' => '1.3.6.1.4.1.31440.10.5.1.3',
        'owDS2423' => '1.3.6.1.4.1.31440.10.1.6',
        'owUnknown' => '1.3.6.1.4.1.31440.10.1.1',
        'owNone' => '1.3.6.1.4.1.31440.10.1.0',
        'owTrapDeviceIndex' => '1.3.6.1.4.1.31440.2.2.1.1',
        'owDeviceFamily' => '1.3.6.1.4.1.31440.10.3.1.5',
        'owTrapDeviceTable' => '1.3.6.1.4.1.31440.2.2',
        'owTrapDeviceSendPointer' => '1.3.6.1.4.1.31440.2.2.1.3',
        'owDeviceInfo' => '1.3.6.1.4.1.31440.10.2',
        'owDS2406NumChnls' => '1.3.6.1.4.1.31440.10.4.1.7',
        'owDS2406PwrSupply' => '1.3.6.1.4.1.31440.10.4.1.8',
        'owDS18B20Table' => '1.3.6.1.4.1.31440.10.5',
        'owTrapIP' => '1.3.6.1.4.1.31440.2.1.1.3',
        'owDeviceTypes' => '1.3.6.1.4.1.31440.10.1',
        'owDS2438PinVoltage' => '1.3.6.1.4.1.31440.10.8.1.3',
        'owDS2406' => '1.3.6.1.4.1.31440.10.1.2',
        'owTrap' => '1.3.6.1.4.1.31440.2',
        'owTrapDeviceHysteresis' => '1.3.6.1.4.1.31440.2.2.1.8',
        'owDS2423CounterA' => '1.3.6.1.4.1.31440.10.7.1.1',
        'owDS2438Current' => '1.3.6.1.4.1.31440.10.8.1.4',
        'owDS2450' => '1.3.6.1.4.1.31440.10.1.8',
        'owDS18B20Entry' => '1.3.6.1.4.1.31440.10.5.1',
        'owDeviceHealth' => '1.3.6.1.4.1.31440.10.3.1.7',
        'owTrapIndex' => '1.3.6.1.4.1.31440.2.1.1.1',
        'eProductName' => '1.3.6.1.4.1.31440.1.2',
        'owDS2406PIOBFlipFlop' => '1.3.6.1.4.1.31440.10.4.1.4',
        'owDeviceIndex' => '1.3.6.1.4.1.31440.10.3.1.1',
        'owDS2406PIOBActivityLatch' => '1.3.6.1.4.1.31440.10.4.1.6',
        'edsEnterprise' => '1.3.6.1.4.1.31440.1',
        'eFirmwareDate' => '1.3.6.1.4.1.31440.1.5',
        'eCompanyName' => '1.3.6.1.4.1.31440.1.1',
        'owDS2406PIOALevel' => '1.3.6.1.4.1.31440.10.4.1.1',
        'owDS2423CounterB' => '1.3.6.1.4.1.31440.10.7.1.2',
        'owDS2438SupplyVoltage' => '1.3.6.1.4.1.31440.10.8.1.2',
        'owEDS0064' => '1.3.6.1.4.1.31440.10.1.9',
        'owDS2408' => '1.3.6.1.4.1.31440.10.1.7',
        'owDS2423Table' => '1.3.6.1.4.1.31440.10.7',
      }
      oids[oid]
    end
  end
end
