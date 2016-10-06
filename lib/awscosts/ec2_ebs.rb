require 'httparty'
require 'json'

class ::Hash
    def deep_merge(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
        self.merge(second.to_h, &merger)
    end
end


class AWSCosts::EBS

  TYPES = {
            'Amazon EBS Magnetic volumes' => :standard,
            'Amazon EBS General Purpose SSD (gp2) volumes' => :gp2,
            'Amazon EBS Provisioned IOPS SSD (io1) volumes' => :io1,
            'ebsSnapsToS3' => :snapshots_to_s3,
            'Amazon EBS Cold HDD (sc1) volumes' => :sc1,
            'Amazon EBS Throughput Optimized HDD (st1) volumes' => :st1
  }

  def initialize data
    @data= data
  end

  def price type = nil
    type.nil? ? @data : @data[type]
  end

  def self.fetch region
    transformed = AWSCosts::Cache.get_jsonp('/pricing/1/ebs/pricing-ebs.min.js') do |data|
      result = {}
      data['config']['regions'].each do |r|
        container = {}
        r['types'].each do |type|
          container[TYPES[type['name']]] = {}
          type['values'].each do |value|
            container[TYPES[type['name']]][value['rate']] = value['prices']['USD'].to_f
          end
        end
        result[r['region']] = container
      end
      result
    end

    transformed2 = AWSCosts::Cache.get_jsonp('/pricing/1/ebs/pricing-ebs-previous-generation.min.js') do |data|
      result = {}
      data['config']['regions'].each do |r|
        container = {}
        r['types'].each do |type|
          container[TYPES[type['name']]] = {}
          type['values'].each do |value|
            container[TYPES[type['name']]][value['rate']] = value['prices']['USD'].to_f
          end
        end
        result[r['region']] = container
      end
      result
    end

    return self.new(transformed[region].deep_merge(transformed2[region]))

  end

end
