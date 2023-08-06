using System.Data;
using System.Data.SqlClient;

namespace PhongVu.Persistence
{
	public abstract class BaseProvider
	{
		IDbConnection connection = null!;
		string connectionString;
		public BaseProvider(string connectionString) => this.connectionString = connectionString;
		public IDbConnection Connection => connection ??= new SqlConnection(connectionString);
	}
}
