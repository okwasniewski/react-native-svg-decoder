import { Text, View, StyleSheet, Image } from 'react-native';

export default function App() {
  return (
    <View style={styles.container}>
      <View style={styles.logoContainer}>
        <Text style={styles.title}>PNG Logo</Text>

        <Image source={require('../assets/google.png')} style={styles.logo} />
      </View>

      <View style={styles.logoContainer}>
        <Text style={styles.title}>SVG Logo</Text>
        <Image source={require('../assets/google.svg')} style={styles.logo} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  logo: {
    width: 200,
    height: 200,
    objectFit: 'contain',
  },
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    margin: 20,
    gap: 20,
  },
  logoContainer: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 20,
  },
});
