using System.Security.Cryptography;
using System.Text;

namespace PhongVu.Infrastructure
{
    public static class Helper
    {
        public static string RandomString(int len)
        {
            char[] arr = new char[len];
            Random random = new Random();
            string pattern = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM0123456789";
            for (int i = 0; i < len; i++)
            {
                arr[i] = pattern[random.Next(pattern.Length)];
            }
            return string.Join("", arr);
        }

        public static byte[] Hash(string plaintext)
        {
            HashAlgorithm algorithm = SHA512.Create();
            return algorithm.ComputeHash(Encoding.ASCII.GetBytes(plaintext));
        }
    }
}