#
# # Ekiden: AWS EventBridge to Slack webhook integration
#
# v.20221024
#
require 'aws-sdk-ssm'
require 'json'
require 'time'
require_relative './neko-http'
require_relative './neko-logger'

# Configure logger
NekoLogger.logger = Logger.new($stdout, formatter: proc { |s, d, n, m| "#{s} : #{m}\n" })
L = NekoLogger.logger
lvl = ENV['NEKO_LOG_LEVEL']
if String === lvl && ['DEBUG', 'INFO', 'WARN', 'ERROR'].include?(lvl.upcase)
  L.level = eval("Logger::#{lvl.upcase}")
end

EB = Aws::EventBridge::Client.new
EB_EKIDEN_BUS = 'prpl-it-ekiden'


def lambda_handler(event:, context:)
  c = config
  unless event['detail-type']
    L.warn('Invalid Lambda trigger, ignoring')
    return
  end
  if event['detail-type'].start_with?(c[:prefix])
    channel = event['detail-type'][c[:prefix].length..-1]
    L.debug("channel: #{channel}")
  else
    L.info('"detail-type" prefix does not match, ignoring')
    return
  end
  url = c[:channels][channel]
  data = event['detail']
  unless url && data
    L.warn('Insufficient data, ignoring')
    return
  end
  r = Neko::HTTP.post_json(url, data)
  if r[:code] == 200
    L.info('Data sent')
    L.debug("Slack: #{r[:message]}; URL: #{url}")
  else
    L.warn("From Slack: #{r[:code]}; #{r[:message]}")
  end
end

def config
  if @config_loaded.nil? || (Time.now - @config_loaded > 3600)
    L.info('Loading config from SSMPS')
    ssm = Aws::SSM::Client.new
    rparams = {
      path: ENV['EKIDEN_SSMPS_CHANNELS_PATH'],
      with_decryption: true,
    }
    @config = {channels:{}}
    ssm.get_parameters_by_path(rparams).parameters.each do |prm|
      k = prm[:name].split('/').last
      @config[:channels][k] = prm[:value]
    end
    @config[:prefix] = ENV['EKIDEN_DETAILTYPE_PREFIX']
    @config_loaded = Time.now
    L.debug("Config loaded #{@config_loaded}")
  end
  @config
end
