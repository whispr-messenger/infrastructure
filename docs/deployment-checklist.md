# Checklist de déploiement

## Avant le déploiement

- [ ] Tests passent en local
- [ ] CI verte sur la PR
- [ ] SonarCloud quality gate OK
- [ ] Review approuvée
- [ ] Pas de secrets dans le code

## Après le déploiement

- [ ] Pods running (`kubectl get pods`)
- [ ] Health checks OK
- [ ] Logs sans erreurs
- [ ] Grafana : pas de spike d'erreurs
