from awsglue.context import GlueContext
import pyspark.sql.functions as F
from pyspark.sql.session import SparkSession


class TestJob:
    def __init__(self, spark_configs: dict = None):
        self._initialize_spark_session(spark_configs=spark_configs)
        self._initialize_glue_context()

    def run(self):
        df = (
            self.spark.createDataFrame(data=self.data())
            .withColumn('age', F.year(F.current_date()) - F.col('birthyear'))
            .withColumn('fullname', F.concat_ws(' ', F.col('firstname'), F.col('lastname')))
        )
        df.repartition(1).write.mode('overwrite').parquet('s3://iptiq-playground-dev/')

    @staticmethod
    def data():
        return [
            {
                'firstname': 'John',
                'lastname': 'Doe',
                'birthyear': 2000
            },
            {
                'firstname': 'Jane',
                'lastname': 'Doe',
                'birthyear': 1980
            }
        ]

    def _initialize_spark_session(self, spark_configs: dict = None):
        builder = SparkSession.builder
        if spark_configs:
            for key, value in spark_configs.items():
                builder = builder.config(key, value)
        self.spark = builder.getOrCreate()

    def _initialize_glue_context(self):
        self.glue_context = GlueContext(self.spark.sparkContext)


if __name__ == '__main__':
    job = TestJob()
    job.run()