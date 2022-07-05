# Tecnologías Blockchain y Contratos Inteligentes

Obligatorio 1er Semestre 2022 - Proyecto Plataforma de Staking

## Descripción del proyecto

El proyecto es una Plataforma de Staking, la cual contiene un token siguiendo el estándar ERC-20, un contrato que permite la compra y venta de
dicho token entre los dueños de la plataforma y los usuarios, y un contrato Farm, encargado de brindar las funcionalidades vinculadas con el Sraking de dicho token.

## Componentes del proyecto

### Contratos inteligentes ([/contracts](/contracts))

En esta carpeta están todos los contratos inteligentes de la solución.

#### TokenContract ([TokenContract.sol](/contracts/TokenContract.sol))
Este contrato representa el token ERC-20. Además de las funcionalidades brindadas por el estándar, tiene la capacidad de <em>mintear</em> y <em>burnear</em> tokens, siguiendo la lógica de negocio definida en la letra del obligatorio.

#### Vault ([Vault.sol](/contracts/Vault.sol))
Este contrato es el encargado de la administración del token ERC-20. Algunas de sus funcionalidades son indicarle a `TokenContract` que <em>mintee</em> y <em>burnee</em> tokens. Manejar la compra y venta del token con otros usuarios, definir los precios, y permitir a los administradores obtener las ganancias de la plataforma. A su vez, para la mayoría de las operaciones maneja un sistema de multifirma.

#### Farm ([Farm.sol](/contracts/Farm.sol))
Este contrato es el encargado de manejar el <em>staking</em> de la plataforma. Permite que los usuarios que presentan tokens puedan <em>stakear</em> y a través de un APR obtener una ganancia <em>"yield"</em>, la cual luego pueden retirar.

### Pruebas Unitarias ([/test](/test))

En esta carpeta están las pruebas unitarias para los contratos inteligentes definidos anteriormente.

### Scripts ([/scripts](/scripts))

TODO: Completar porque vamos a tener solo 1 script que deploye todo.

## Pasos para hacer el Setup del repositorio

Requisitos: Tener instalado Node.js, se puede descargar en este [link](https://nodejs.org/en/download/) (recomendamos la versión LTS)

Abrir una terminal y correr el siguiente comando en el root del proyecto:
```
npm install
```

## Pasos para hacer el Deploy del proyecto

TODO: Completar.

## Pasos para hacer la ejecución de test del proyecto

Requisitos: [Setup del repositorio](#pasos-para-hacer-el-setup-del-repositorio)

Abrir una terminal y correr el siguiente comando en el root del proyecto:
```
npm test
```

## Address de contratos deployados en testnet

TODO: Completar.

## Integrantes del equipo
|      Nombre     | Nro. de Estudiante |             Address Registrada             |
|:---------------:|:------------------:|:------------------------------------------:|
|  Diego Franggi  |       210434       | 0xA947783b803D20032c12f58cdE0Dd20b73fE57dF |
| Mathías Gertner |       193783       | 0x335bBEA03eb4773D71F56eA425cFD7AD79B89B86 |
|   Bruno Pintos  |       214108       | 0x21176324dc254a413f195A1732055ee43AD9A7Bf |
